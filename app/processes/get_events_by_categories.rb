class GetEventsByCategories

  def self.call(*args)
    self.new(*args).call
  end

  def initialize(categories, opts)
    @categories          = categories
    @opts                = opts
    @opts[:misspellings] = false
  end

  OPERATORS = {
    "OR"           => { operator: "or" },
    "Match Phrase" => { match: :phrase },
    "AND"          => {}
  }

  def call
    @results = []
    categories = @categories.split(',')
    categories.each do |category|
      category = EventCategory.find_by(slug: category)
      next unless category.present?
      multiple_phrase_matching(category) and next if category.query_modifier == "Match Phrase"
      run_search(category, category.query)
    end
    @results.uniq
  end

  private

    def multiple_phrase_matching(category)
      phrases = category.query.split(',')
      phrases.each do |phrase|
        run_search(category, phrase.strip)
      end
    end

    def run_search(category, query)
      modifier = OPERATORS[category.query_modifier] || {}
      @results += EventInstance.search(query, @opts.merge(modifier)).results
    end

end