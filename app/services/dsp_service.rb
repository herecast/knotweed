# this is both a refactoring of the OntotextController
# and a first step towards abstracting all DSP related calls
# into this service so the app code doesn't need to worry about it.
module DspService
  include HTTParty
  extend self

  # set debug_output based on environment
  def set_debug_output
    unless Rails.env.production?
      debug_output
    end
  end
  set_debug_output

  # override post method here to insert auth config
  def post(dest, options)
    options.merge!({ :basic_auth => 
                      { username: Figaro.env.ontotext_api_username,
                        password: Figaro.env.ontotext_api_password },
                     :timeout => 10*60 }) 
    super(dest, options)
  end

  # calls /extract on a given piece of content (Content or ListservContent)
  # and returns the JSON parsed response
  #
  # @param content [Content, ListservContent] the object to send to the DSP
  # @param repo [Repository] the repository to make the request to
  # @return [Hash] annotated response from the DSP
  def extract(content, repo=Repository.production_repo)
    JSON.parse(post(repo.annotate_endpoint + '/extract',
        { body: content.to_xml,
          headers: { 'Content-type' => "application/vnd.ontotext.ces.document+xml;charset=UTF-8",
                     'Accept' => "application/vnd.ontotext.ces.document+json" }}))
  end

  # update DSP (recommendation api) with content_id, user and timestamp for each
  # visit to a content detail page
  #
  # @param content [Content]
  # @param user [User] the user who visited
  # @param repo [Repository] repository to post to
  def record_user_visit(content, user, repo=Repository.production_repo)
    post(repo.recommendation_endpoint + '/user', {
      body: {
        key: Figaro.env.ontotext_recommend_key,
        userid: user.email,
        contentid: Content::BASE_URI + "/#{content.id}"
      },
    })
  end

  # Post to Ontotext's new CES & Recommendations API
  # - passes content thru pipeline (annotation)
  # - formats annotation and posts to recommendation engine
  # - persists content to graphdb and updates active promo if applicable
  # @param repo [Repo] the repo object
  def publish(content, repo=Repository.production_repo)
    annotate_resp = extract(content, repo)
    if annotate_resp['id'].include? content.document_uri
      content.update_category_from_annotations(annotate_resp)
      rec_doc = create_recommendation_doc_from_annotations(content, annotate_resp)

      response = post(repo.recommendation_endpoint + "/content?key=#{Figaro.env.ontotext_recommend_key}", 
          { headers: { "Content-type" => "application/json",
                       "Accept" => "application/json" },
            body: [rec_doc].to_json } )

      if response['type'] == 'SUCCESS'
        result = true
        content.repositories << repo unless content.repositories.include? repo

        persist_to_graph_db(content, annotate_resp, repo)
        # trigger updating hasActivePromotion if publish succeeded
        if content.has_active_promotion?
          self.update_promotion('add_active', content.id, repo)
        end

        # trigger updating hasPaidPromotion if publish succeeded
        if content.has_paid_promotion?
          self.update_promotion('add_paid', content.id, repo)
        end
      else
        result = false
      end
    else
      result = false
    end
    if result
      true
    else
      raise DspExceptions::UnableToPublish(content, repo, response.body)
    end
  end

  # called by export_pre_pipeline_xml
  # retrieves Gate Document immediately prior to pipeline processing
  #
  # @param content [Content]
  # @param pre_or_post [String] either 'pre' or 'post' pipeline XML to export
  # @param repo [Repository]
  # @return response [String]
  def get_pipeline_xml(content, pre_or_post, repo=Repository.production_repo)
    # should never be called with anything but 'pre' or 'post' but just in case...
    raise ArgumentError, 'Argument must be either "pre" or "post"' unless ['pre', 'post'].include? pre_or_post
    post("#{repo.dsp_endpoint}/process#{pre_or_post.titlecase}Pipeline", { body: content.to_xml })
  end

  # Creates an Ontotext "recommendation" doc suitable for submission to the API
  # from annotations returned by the content extraction service
  #
  # @param content [Content]
  # @param annotations [Hash]
  # @return [Hash] the recommendation doc
  def create_recommendation_doc_from_annotations(content, annotations)
    rec_doc = { id: annotations['id'],
                title: content.title,
                content: content.sanitized_content,
                published: content.pubdate.utc.iso8601,
                url: content.url,
                parent_category: content.root_content_category.name,
                has_active_promo: content.has_active_promotion?,
                tags: [],
                keyphrases: [],
    }

    extract_mentions_from_annotations(annotations).each do |m|
      if ["Location", "Person", "Organization"].include? m[:type]
        rec_doc[:tags] << m[:value]
      else
        rec_doc[:keyphrases] << m[:value]
      end
    end

    rec_doc[:tags] = rec_doc[:tags].join(" ")
    rec_doc[:keyphrases] = rec_doc[:keyphrases].join(" ")

    rec_doc
  end

  # queries the DSP for similar content
  #
  # @param content [Content]
  # @param num_similar [Integer]
  # @param repo [Repository]
  def get_similar_content_ids(content, num_similar=8, repo=Repository.production_repo)
    # for event and market categories, use extra_param boost to favor content w/in last 30 days
    # note -- the "category" method being called on self here
    # returns the text label of the associated content_category
    if ["event", "market", "offered", "wanted", "for_free", "sale_event"].include? content.category
      extra_param = "&mlt.boostexpr=recip(ms(NOW/HOUR,published),2.63e-10,1,1)"
    else
      extra_param = ''
    end
    similar_url = repo.recommendation_endpoint + '/recommend/contextual?contentid=' +
      content.uri + "&key=#{Figaro.env.ontotext_recommend_key}" +
      "&count=#{num_similar}" + "&sort=rel" + extra_param
    response = HTTParty.get(similar_url)
    if response['articles'].present?
      similar_ids = response['articles'].map do |art|
        art['id'].split('/')[-1].to_i
      end
      similar_ids
    else
      []
    end
  end

  # queries the DSP for active, relevant ads then returns those with inventory
  #
  # @param content [Content]
  # @param max_return [Integer]
  # @param repo [Repository]
  def get_related_promo_ids(content, max_return=3, repo=Repository.production_repo)
    #create request url
    related_promo_url = repo.recommendation_endpoint + '/recommend/contextual?contentid=' +
      content.uri + "&key=#{Figaro.env.ontotext_recommend_key}" +
      "&count=#{max_return}" + "&sort=rel&filter=has_active_promo:true"
    #submit request
    response = HTTParty.get(related_promo_url)
    #get relevance score threshold (env variable)
    score_threshold = Figaro.env.promo_relevance_score_threshold.to_f
    #select relevant active ads with inventory
    #TODO: should really refactor this to handle has-inventory downstream
    if response['articles'].present?
      promo_ids = response['articles'].select do |art|
        art['score'] > score_threshold && PromotionBanner.for_content(art['id'].split('/')[-1].to_s).has_inventory.count > 0
      end
    else
      []
    end
  end

  # Extracts mentions (e.g. Person, Organization, Keyphrases) from full annotations
  def extract_mentions_from_annotations(annotations)
    mentions = []
    annotations['annotation-sets'].each do |s| 
      s['annotation'].each do |a|
        value = nil
        a['feature-set'].each do |feature|
          value = feature['value']['value'] if feature['name']['name'] == "inst"
        end
        mentions << { type: a['type'], value: value }
      end
    end
    mentions
  end

  # Persists this content to GraphDB as a series of tuples.
  def persist_to_graph_db(content, annotations, repo)
    #create/populate graph
    graph = RDF::Graph.new
    pub = RDF::Vocabulary.new("http://ontology.ontotext.com/publishing#")
    category = RDF::Vocabulary.new("http://data.ontotext.com/Category/")
    facets = RDF::Vocabulary.new("http://data.ontotext.com/facets/facetLink#")
    features = RDF::Vocabulary.new("http://data.ontotext.com/watt/Feature/")
    id_uri = RDF::URI(annotations['id'])

    graph << [RDF::URI(annotations['id']), RDF.type, pub['Document']]
    fields = [
      [pub['title'], content.title],
      [pub['creationDate'], content.pubdate.utc.iso8601],
      [pub['content'], content.sanitized_content],
      [pub['hasCategory'], category[content.publish_category]],
      [pub['annotatedContent'], JSON.generate(annotations)]
    ]
    fields.each do |f|
      graph << [id_uri, f[0], f[1]]
    end

    extract_mentions_from_annotations(annotations).each do |m|
      graph << [id_uri, facets[m[:type]], RDF::URI(m[:value])]
    end

    sparql = ::SPARQL::Client.new repo.graphdb_endpoint

    #clean out existing annotatedContent for this uri
    query = File.read(Rails.root.join("lib", "queries", "remove_statements.rq")) %
            {content_id: content.id}
    sparql.update(query, { endpoint: repo.graphdb_endpoint + "/statements" })

    annotations['document-parts']['feature-set'].each do |feature|
     # populate features ONLY IF they have a value
      if feature['value']['value'].present?
        feature_key = features[SecureRandom.uuid]
        graph << [feature_key, RDF.type, pub['Feature']]
        graph << [feature_key, pub['featureName'], feature['name']['name']]
        graph << [feature_key, pub['featureValue'], feature['value']['value']]
        graph << [id_uri, pub['Feature'], feature_key]
      end
    end

    query = "INSERT DATA {"+graph.dump(:ntriples)+"}"

    sparql.update(query, { endpoint: repo.graphdb_endpoint + "/statements" })
    graph
  end

  def update_promotion(type, content_id, repo)
    query = File.read("./lib/queries/#{type}_promo.rq") % {content_id: content_id}
    sparql = ::SPARQL::Client.new repo.graphdb_endpoint
    sparql.update(query, { endpoint: repo.graphdb_endpoint + "/statements" })
  end
end
