require 'rails_helper'

RSpec.describe JasperService do
  subject { JasperService }

  it { is_expected.to respond_to(:submit_job) }

  describe '#submit_job' do
    subject { JasperService.submit_job(report_job.report_job_args(report_job_recipient, is_review)) }

    let(:stub_data) {
      {
        report_path: '/test',
        report_params: { test_param: 'param value' },
        output_formats: 'PDF,HTML',
        review_folder: '/review',
        overwrite: true,
        email_subject: 'Test Subject',
        alert_recipients: ['john@test.com'],
        cc_emails: ['johncc@test.com'],
        bcc_emails: ['johnbcc@test.com']
      }
    }

    let(:report) { FactoryGirl.create :report,
      report_path: stub_data[:report_path], repository_folder: stub_data[:review_folder],
      overwrite_files: stub_data[:overwrite], output_formats_review: stub_data[:output_formats],
      email_subject: stub_data[:email_subject], alert_recipients: stub_data[:alert_recipients].join(','),
      cc_emails: stub_data[:cc_emails].join(','), bcc_emails: stub_data[:bcc_emails].join(',') }
    let(:report_job) { FactoryGirl.create :report_job, report: report }
    let(:report_recipient) { FactoryGirl.create :report_recipient, report: report }
    let(:report_job_recipient) { FactoryGirl.create :report_job_recipient,
      report_recipient: report_recipient, report_job: report_job }
    let!(:rj_parameter) { FactoryGirl.create :report_job_param,
      report_job_paramable: report_job, param_name: stub_data[:report_params].keys[0],
      param_value: stub_data[:report_params].values[0] }
    let(:filename) { report_job.filename(report_job_recipient) }

    let(:request_body_stub) {
      {
        source:                {
          reportUnitURI: stub_data[:report_path],
          parameters:    {parameterValues: stub_data[:report_params].merge({ user_id: report_recipient.user.id })},
        },
        trigger:               {
          simpleTrigger:
            {
              misfireInstruction: 0,
              startType:          1,
              timezone:           "Etc/UTC",
              version:            0,
              occurrenceCount:    1,
            }
          },
        baseOutputFilename:    filename,
        label:                 filename,
        outputTimeZone:        "Etc/UTC",
        alert:  {
          version:                 -1,
          recipient:               "OWNER_AND_ADMIN",
          toAddresses:             {address: stub_data[:alert_recipients]},
          jobState:                "FAIL_ONLY",
          subject:                 "A JasperReport run has failed",
          messageText:             "Success",
          messageTextWhenJobFails: "Failure details:",
          includingStackTrace:     true,
          includingReportJobInfo:  true,
        },
        username:              JasperService::SERVER_USER,
        version:               0,
        outputFormats:         { outputFormat: stub_data[:output_formats].split(',') },
        repositoryDestination: {
          folderURI:                         stub_data[:review_folder],
          overwriteFiles:                    stub_data[:overwrite],
          saveToRepository:                  is_review,
          sequentialFilenames:               true,
          timestampPattern:                  "yyyyMMddHHmm",
          usingDefaultReportOutputFolderURI: false,
          version:                           0,
        }
      }
    }
    context 'for a review request' do
      let(:is_review) { true }

      it 'puts to the jasper endpoint' do
        request = stub_request(:put, JasperService::SERVER_HOST + "/rest_v2/jobs").with(
          body: request_body_stub
        )
        subject
        expect(request).to have_been_requested
      end
    end

    context 'for a final request' do
      let(:is_review) { false }

      let(:request_body_stub_with_mailing) {
        request_body_stub.merge({
          mailNotification: {
            toAddresses:                     {address: report_job_recipient.to_addresses},
            ccAddresses:                     {address: stub_data[:cc_emails]},
            bccAddresses:                    {address: stub_data[:bcc_emails]},
            subject:                         stub_data[:email_subject],
            messageText:                     nil,
            resultSendType:                  "SEND_EMBED",
            includingStackTraceWhenJobFails: false,
            skipEmptyReports:                true,
            skipNotificationWhenJobFails:    false,
            version:                         0
          }
        })
      }

          

      it 'puts to the jasper endpoint' do
        request = stub_request(:put, JasperService::SERVER_HOST + "/rest_v2/jobs").with(
          body: request_body_stub_with_mailing
        )
        subject
        expect(request).to have_been_requested
      end
    end
  end
end
