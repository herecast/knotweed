require "java"
$CLASSPATH << "#{Figaro.env.kim_home}/kim-api.jar"
$CLASSPATH << "#{Figaro.env.kim_home}/lib/.*jar"

java_import java.rmi.RemoteException
java_import com.ontotext.kim.client.GetService
java_import com.ontotext.kim.client.KIMService
java_import com.ontotext.kim.client.corpora.CorporaAPI
java_import com.ontotext.kim.client.documentrepository.DocumentRepositoryAPI
java_import com.ontotext.kim.client.semanticannotation.SemanticAnnotationAPI
java_import com.ontotext.kim.client.query.QueryAPI
java_import com.ontotext.kim.client.coredb.CoreAPI

class ContentsController < ApplicationController
  def index
    @contents = Content.all

    begin
      KIMService serviceKim = GetService.from()
      @version = serviceKim.getVersion()
    rescue StandardError => err
      print "Error connecting to KIM: " + err
    end
      

  end

  def show
    @content = Content.find(params[:id])
  end
end
