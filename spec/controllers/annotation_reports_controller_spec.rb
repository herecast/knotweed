require 'spec_helper'

describe AnnotationReportsController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe 'POST #create' do
    context 'Given name, content_id and repository_id params' do
      let(:name) { "my report" }
      let(:repo) { FactoryGirl.create :repository }
      let(:content) { FactoryGirl.create :content }
      let(:annotations) {
        {
          'annotation-sets' => [
            {
              'annotation' => [
                {
                  'id' => 1,
                  'startnode' => '',
                  'endnode' => '',
                  'type' => '',
                  'feature-set' => [
                    {
                      'name' => {
                        'name' =>  'isGenerated'
                      },
                      'value' => {
                        'value' => true
                      }
                    },
                    {
                      'name' => {
                        'name' =>  'string'
                      },
                      'value' => {
                        'value' => 'annotated string...'
                      }
                    },
                    {
                      'name' => {
                        'name' =>  'class'
                      },
                      'value' => {
                        'value' => 'RecognizedClass'
                      }
                    },
                    {
                      'name' => {
                        'name' =>  'inst'
                      },
                      'value' => {
                        'value' => 'the instance'
                      }
                    },
                    {
                      'name' => {
                        'name' =>  'originalClass'
                      },
                      'value' => {
                        'value' => 'TheLookupClass'
                      }
                    },
                    {
                      'name' => {
                        'name' =>  'isTrusted'
                      },
                      'value' => {
                        'value' => true
                      }
                    },
                    {
                      'name' => {
                        'name' =>  'rule'
                      },
                      'value' => {
                        'value' => "Rules? nobody likes rules."
                      }
                    }
                  ]
                },
                {
                  'id' => 2,
                  'startnode' => '',
                  'endnode' => '',
                  'type' => '',
                  'feature-set' => [
                    {
                      'name' => {
                        'name' =>  'isGenerated'
                      },
                      'value' => {
                        'value' => true
                      }
                    },
                    {
                      'name' => {
                        'name' =>  'string'
                      },
                      'value' => {
                        'value' => 'annotated string...'
                      }
                    },
                    {
                      'name' => {
                        'name' =>  'class'
                      },
                      'value' => {
                        'value' => 'RecognizedClass'
                      }
                    },
                    {
                      'name' => {
                        'name' =>  'inst'
                      },
                      'value' => {
                        'value' => 'the instance'
                      }
                    },
                    {
                      'name' => {
                        'name' =>  'originalClass'
                      },
                      'value' => {
                        'value' => 'TheLookupClass'
                      }
                    },
                    {
                      'name' => {
                        'name' =>  'isTrusted'
                      },
                      'value' => {
                        'value' => true
                      }
                    },
                    {
                      'name' => {
                        'name' =>  'rule'
                      },
                      'value' => {
                        'value' => "Rules? nobody likes rules."
                      }
                    }
                  ]
                }
              ]
            }
          ]
        }
      }
      let(:ontotext_return) {
        <<-eos
        {
          "results": {
            "bindings": [
              {
                "annotation": {
                  "value": #{annotations.to_json.to_json}
                }
              }
            ]
          }
        }
        eos
      }

      before do
        allow(OntotextController).to receive(:get_annotations).and_return(ontotext_return)

        # we don't care about other calls to ontotext
        allow_any_instance_of(Annotation).to receive(:find_edges).and_return(nil)
      end

      subject { post :create, name: name, repository_id: repo.id, content_id: content.id }

      it 'creates an AnnotationReport record' do
        expect{ subject }.to change { AnnotationReport.count }.by(1)
        record = AnnotationReport.last
        expect(record.json_response).to eql annotations.to_json
        expect(record.name).to eql name
      end

      it 'creates related Annotation records' do
        expect{ subject }.to change{
          Annotation.count
        }.by(2)
        annotation_record = AnnotationReport.last
        records = Annotation.all
        expect(records).to satisfy{|recs| recs.all?{|r| r.annotation_report_id == annotation_record.id }}
      end

    end
  end

  describe 'GET #edit' do
    before do
      @annotation_report = FactoryGirl.create :annotation_report
    end

    subject { get(:edit, id: @annotation_report.id, :format => "js") }

    it "should respond with 200 status code" do
      subject
      expect(response.code).to eq '200'
    end
  end

  describe 'GET #table_row' do
    before do
      @annotation_report = FactoryGirl.create :annotation_report
    end

    subject { get :table_row, id: @annotation_report.id }

    it "shoud respond with 200 status code" do
      subject
      expect(response.code).to eq '200'
    end
  end

  describe 'DELETE #destroy' do
    before do
      @annotation_report = FactoryGirl.create :annotation_report
    end

    subject { delete :destroy, id: @annotation_report.id }

    it "should delete annotation report" do
      expect{ subject }.to change{ AnnotationReport.count }.by(-1)
    end
  end

  describe 'GET #export' do
    before do
      @annotation_report = FactoryGirl.create :annotation_report
    end

    subject { get(:export, content_id: @annotation_report.id, :format => "csv") }

    it "should respond with 200 status code" do
      subject
      expect(response.code).to eq '200'
    end
  end
end
