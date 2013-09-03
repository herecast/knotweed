java_import java.rmi.RemoteException
java_import com.ontotext.kim.client.GetService
java_import com.ontotext.kim.client.KIMService
java_import com.ontotext.kim.client.corpora.CorporaAPI
java_import com.ontotext.kim.client.documentrepository.DocumentRepositoryAPI
java_import com.ontotext.kim.client.documentrepository.DocumentQuery
java_import com.ontotext.kim.client.semanticannotation.SemanticAnnotationAPI
java_import com.ontotext.kim.client.query.QueryAPI
java_import com.ontotext.kim.client.coredb.CoreAPI
java_import com.ontotext.kim.client.query.DocumentQueryResult

java_import org.openrdf.model.vocabulary.RDFS
java_import org.openrdf.model.impl.URIImpl


class ContentsController < ApplicationController

  @@serviceKim = GetService.from
  @@apiDR = @@serviceKim.getDocumentRepositoryAPI
  @@semanticAPI = @@serviceKim.getSemanticRepositoryAPI

  def index
    @version = @@serviceKim.getVersion()

    query = DocumentQuery.new() 
    query.setMaxResultLength(10)
    query.setSortFeature("TIMESTAMP", true)
    listDocIDs = @@apiDR.getDocumentIds(query)
    @contents = []
    listDocIDs.each do |id|
      @contents << @@apiDR.loadDocument(id.getDocumentId())
    end
  end

  def show
    document = @@apiDR.loadDocument(params[:id].to_i)
    @content = document.content
    @features = document.features

    # get entities
    annotations = document.getAnnotations
    @people = []
    @orgs = []
    @locations = []
    annotations.each do |a|
      resource_uri = a.features["inst"]
      unless resource_uri.nil?
        properties = @@semanticAPI.evaluateSelectSeRQL "select distinct MainLabel " + 
            "from {<" + resource_uri + ">} <" + RDFS::LABEL.to_s + "> {MainLabel}"
        properties.each do |p|
          if a.type == "Person"
            @people << p.get(0).to_s unless @people.include? p.get(0).to_s
          elsif a.type == "Organization"
            @orgs << p.get(0).to_s unless @orgs.include? p.get(0).to_s
          elsif a.type == "Location"
            @locations << p.get(0).to_s unless @locations.include? p.get(0).to_s
          end
        end
      end
    end

  end
end
