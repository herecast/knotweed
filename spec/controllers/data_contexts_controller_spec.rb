require 'spec_helper'

describe DataContextsController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe '#index' do
    let(:query) { {'context_cont' => 'search'} }
    describe 'session and search' do
      it 'remembers last search' do
        session[:data_contexts_search] = query

        mock_return = double(result: DataContext)
        expect(DataContext).to receive(:ransack).with(query).and_return(mock_return)
        get :index
      end

      context '?reset=true' do
        before do
          session[:data_contexts_search] = query
        end

        it 'resets saved search from session' do
          get :index, {reset: true}
          expect(session[:data_contexts_search]).to be_nil
        end
      end

      context 'given parameter ?q="' do
        it 'saves the search in session' do
          session[:data_contexts_search] = nil
          get :index, q: query
          expect( session[:data_contexts_search] ).to eql query
        end
      end
    end

    context 'given a query' do
      it 'passes the query to ransack' do
        mock_return = double(result: DataContext)
        expect(DataContext).to receive(:ransack).with(query).and_return(mock_return)
        get :index, q: query
      end

      it 'assigns @data_contexts with result' do
        result = FactoryGirl.create_list :data_context, 3
        mock_return = double(result: result)
        expect(DataContext).to receive(:ransack).with(query).and_return(mock_return)

        get :index, q: query

        expect( assigns(:data_contexts) ).to eql result
      end

      context '?status=Loaded"' do
        it 'converts to a ransack query: loaded_eq = true' do
          expected_query = query.merge({'loaded_eq' => true})
          mock_return = double(result: DataContext)
          expect(DataContext).to receive(:ransack).with(
            expected_query
          ).and_return(mock_return)

          get :index, q: query, status: "Loaded"
        end
      end

      context '?status=Unloaded' do
        it 'converts to a ransack query: loaded_eq = false' do
          expected_query = query.merge({'loaded_eq' => false})
          mock_return = double(result: DataContext)
          expect(DataContext).to receive(:ransack).with(
            expected_query
          ).and_return(mock_return)

          get :index, q: query, status: "Unloaded"
        end
      end

      context '?status=Archived' do
        it 'converts to a ransack query: archived_eq = true' do
          expected_query = query.merge({'archived_eq' => true})
          mock_return = double(result: DataContext)
          expect(DataContext).to receive(:ransack).with(
            expected_query
          ).and_return(mock_return)

          get :index, q: query, status: "Archived"
        end
      end
    end
  end

  describe '#update' do
    context 'given attributes' do
      subject { FactoryGirl.create :data_context }
      let(:attrs) { {'context' => "new Context string"} }

      before do
        allow(DataContext).to receive(:find).and_return(subject)
      end

      it 'updates the instance' do
        put :update, id: subject.id, data_context: attrs
        expect(subject.reload.context).to eql attrs['context']
      end

      context 'valid update' do
        before do
          allow(subject).to receive(:update_attributes).and_return(true)
        end

        it 'redirects to data_contexts_path' do
          put :update, id: subject.id, data_context: attrs
          expect(response).to redirect_to(data_contexts_path)
        end
      end

      context 'invalid update' do
        before do
          allow(subject).to receive(:update_attributes).and_return(false)
        end

        it 'rerenders "edit" template' do
          put :update, id: subject.id, data_context: attrs
          expect(response).to render_template('data_contexts/edit')
        end
      end
    end
  end

  describe '#create' do
    let(:attrs) { FactoryGirl.attributes_for :data_context }

    context 'given valid attributes' do
      it 'creates a data_context' do
        expect {
          post :create, data_context: attrs
        }.to change {
          DataContext.count
        }.by(1)
      end

      it 'redirects to data_contexts_path' do
        post :create, data_context: attrs
        expect(response).to redirect_to(data_contexts_path)
      end
    end

    context 'invalid' do
      before do
        allow_any_instance_of(DataContext).to receive(:save).and_return(false)
      end

      it 'rerenders "new" template' do
        post :create, data_context: attrs
        expect(response).to render_template('data_contexts/new')
      end
    end
  end
end
