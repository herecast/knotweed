shared_examples_for "Location based index" do
  let(:content_type) { raise "Must define let(:content_type) as symbol" }

  let(:content_attributes) { {} }

  let(:assigned_var) {
    assigns(content_type.to_s.pluralize.to_sym)
  }

  describe 'querying by location_id' do
    let(:location) {
      FactoryGirl.create :location, coordinates: [0,0]
    }

    let!(:base_located) {
      FactoryGirl.create :content, content_type,
        content_attributes.merge(
          content_locations: [
            FactoryGirl.create(:content_location,
              location_type: 'base',
              location: location
            )
          ],
        )
    }

    let!(:about_located) {
      FactoryGirl.create :content, content_type,
        content_attributes.merge(
          content_locations: [
            FactoryGirl.create(:content_location,
              location_type: 'about',
              location: location
            )
          ],
        )
    }

    let!(:standard_located) {
      FactoryGirl.create :content, content_type,
        content_attributes.merge(
          content_locations: [
            FactoryGirl.create(:content_location,
              location_type: nil,
              location: location
            )
          ],
        )
    }

    it 'returns records with base or about location matching' do
      get :index, format: :json, location_id: location.slug

      expect(assigned_var.count).to eql 2
      expect(assigned_var).to include about_located, base_located
    end

    context 'radius based searching' do
      let(:radius) { 10 }
      let!(:location_within_radius) {
          FactoryGirl.create :location,
            coordinates: Geocoder::Calculations.random_point_near(
              location,
              radius, units: :mi
            )
        }

      subject { get :index, format: :json, location_id: location.slug, radius: radius }

      context 'posts exist promoted within radius' do
        let!(:posts) {
          FactoryGirl.create_list :content, 2,
            content_type,
            content_attributes.merge(
              content_locations: [
                ContentLocation.new(
                  location: location_within_radius
                ),
                ContentLocation.new(
                  location: FactoryGirl.create(:location)
                )
              ]
            )
        }

        it 'returns those posts within the radius' do
          subject
          expect(assigned_var).to include *posts
        end

      end

      context 'post promoted to only one town, within radius' do
        let!(:post) {
          FactoryGirl.create :content, content_type,
            content_attributes.merge(
              content_locations: [
                FactoryGirl.create(:content_location,
                  location_type: 'base',
                  location: location_within_radius
                )
              ]
            )
        }

        it 'does not return the post' do
          subject
          expect(assigned_var).to_not include post
        end
      end
    end
  end
end
