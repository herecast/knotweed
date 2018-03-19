module JasperService
  include HTTParty
  extend self

  SERVER_HOST      = Figaro.env.jasper_server_host
  SERVER_USER      = Figaro.env.jasper_server_user
  SERVER_PASS      = Figaro.env.jasper_server_password

  base_uri SERVER_HOST

  def submit_job(output_file_name:, output_formats:, run_type:, review_folder:,
    overwrite:, report_params:, report_path:, email_subject:, recipients:, alert_recipients:,
                cc_emails:, bcc_emails:)

    job_data = {
      source:                {
        reportUnitURI: report_path,
        parameters:    {parameterValues: report_params},
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
      baseOutputFilename:    output_file_name,
      label:                 output_file_name,
      outputTimeZone:        "Etc/UTC",
      alert:  {
        version:                 -1,
        recipient:               "OWNER_AND_ADMIN",
        toAddresses:             {address: alert_recipients},
        jobState:                "FAIL_ONLY",
        subject:                 "A JasperReport run has failed",
        messageText:             "Success",
        messageTextWhenJobFails: "Failure details:",
        includingStackTrace:     true,
        includingReportJobInfo:  true,
      },
      username:              SERVER_USER,
      version:               0,
      outputFormats:         { outputFormat: output_formats.split(',') },
      repositoryDestination: {
        folderURI:                         review_folder,
        overwriteFiles:                    overwrite,
        saveToRepository:                  run_type == :review ? true : false,
        sequentialFilenames:               true,
        timestampPattern:                  "yyyyMMddHHmm",
        usingDefaultReportOutputFolderURI: false,
        version:                           0,
      }
    }

    if run_type == :send
      job_data[:mailNotification] = {
        toAddresses:                     {address: recipients},
        ccAddresses:                     {address: cc_emails},
        bccAddresses:                    {address: bcc_emails},
        subject:                         email_subject,
        messageText:                     nil,
        resultSendType:                  "SEND_EMBED",
        includingStackTraceWhenJobFails: false,
        skipEmptyReports:                true,
        skipNotificationWhenJobFails:    false,
        version:                         0
      }
    end

    result = put("/rest_v2/jobs",
                   body:       job_data.to_json,
                   headers:    {'Content-Type' => 'application/json'},
                   basic_auth: {username: SERVER_USER, password: SERVER_PASS})
    result
  end

end
