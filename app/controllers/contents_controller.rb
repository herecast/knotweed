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


class ContentsController < ApplicationController

  @@serviceKim = GetService.from()
  @@apiDR = @@serviceKim.getDocumentRepositoryAPI()

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
  end
end
