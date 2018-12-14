# frozen_string_literal: true

module BillDotComService
  include HTTParty

  extend self

  DEV_KEY = ENV['BILL_DOT_COM_API_KEY']

  CHART_OF_ACCOUNT_ID = ENV['BILL_DOT_COM_COA_ID']

  base_uri ENV['BILL_DOT_COM_API_ENDPOINT']

  def authenticate
    options = {
      body: {
        'userName' => ENV['BILL_DOT_COM_USERNAME'],
        'password' => ENV['BILL_DOT_COM_PASSWORD'],
        'orgId' => ENV['BILL_DOT_COM_ORG_ID'],
        'devKey' => DEV_KEY
      }
    }
    response = detect_error(post('/Login.json', options))
    response['response_data']['sessionId']
  end

  # sends payment to Bill.com API
  def send_payment(vendor_name:, amount:, invoice_number:, invoice_date:, sid: nil)
    session_id = sid || authenticate

    vendor_id = find_vendor(vendor_name, session_id)

    due_date = invoice_date + 9.days

    create_bill(
      vendor_id: vendor_id,
      amount: amount,
      invoice_number: invoice_number,
      invoice_date: invoice_date,
      due_date: due_date,
      sid: session_id
    )

    # we are now just creating bills and allowing approval and payment to occur in Bill.com UI
    # pay_bill(vendor_id: vendor_id, bill_id: bill_id, amount: amount, sid: session_id)
  end

  def find_vendor(name, sid = nil)
    data = {
      entity: 'Vendor',
      term: name
    }
    response = detect_error(post('/SearchEntity.json', options_with_auth(data, sid)))
    response['response_data'][0]['id']
  end

  def create_bill(vendor_id:, amount:, invoice_number:, invoice_date:, due_date:, sid: nil)
    data = {
      'obj' => {
        'entity' => 'Bill',
        'vendorId' => vendor_id,
        'invoiceNumber' => invoice_number.to_s,
        'invoiceDate' => invoice_date.to_s,
        'dueDate' => due_date.to_s,
        'billLineItems' => [{
          'entity' => 'BillLineItem',
          'amount' => amount,
          'chartOfAccountId' => CHART_OF_ACCOUNT_ID
        }]
      }
    }
    response = detect_error(post('/Crud/Create/Bill.json', options_with_auth(data, sid)))
    response['response_data']['id']
  end

  def pay_bill(vendor_id:, bill_id:, amount:, sid: nil)
    data = {
      'vendorId' => vendor_id,
      'billPays' => [{
        'billId' => bill_id,
        'amount' => amount
      }]
    }
    response = detect_error(post('/PayBills.json', options_with_auth(data, sid)))
  end

  protected

  def options_with_auth(data, sid = nil)
    session_id = sid || authenticate
    {
      headers: {
        'Content-Type' => 'application/x-www-form-urlencoded'
      },
      body: {
        sessionId: session_id,
        devKey: DEV_KEY,
        data: data.to_json
      }
    }
  end

  # instead of using HTTP codes for errors, Bill.com just has a
  # `response_status` field that is 0 for success, 1 for failure
  def detect_error(response)
    if response['response_status'] == 1
      raise BillDotComExceptions::UnexpectedResponse, response['response_data']['error_message']
    end

    response
  end

  # set debug_output based on environment
  def set_debug_output
    debug_output unless Rails.env.production?
  end
  set_debug_output
end
