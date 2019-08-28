module Promotions
  class BuildExternalAdvertiserReport
    include ActionView::Helpers::NumberHelper

    def self.call(*args)
      self.new(*args).call
    end

    def initialize(organization:, campaigns:)
      @organization = organization
      @campaigns = campaigns
    end

    def call
      @pdf = WickedPdf.new.pdf_from_string(pdf_string, dpi: 300)
      build_temp_pdf
      @organization.external_advertiser_reports.create!(pdf: @tempfile, title: pdf_name)
      { name: pdf_name, pdf: @pdf }
    end

    private

      def pdf_string
        html_path = './app/views/promotions_mailer/external_advertiser_report.html.erb'
        ERB.new(File.read(html_path)).result(binding)
      end

      def pdf_name
        "#{@organization.name}-ad-report-#{Date.current.strftime('%m/%d/%y')}.pdf"
      end

      def build_temp_pdf
        @tempfile = Tempfile.new(["#{Rails.root}/tmp/#{URI::encode(pdf_name)}", ".pdf"])
        @tempfile.binmode
        @tempfile.write @pdf
        @tempfile.close
      end

  end
end