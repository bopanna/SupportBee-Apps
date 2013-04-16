module Shopify
  module ActionHandler
    def button

      begin
        create_blog(payload.overlay.title, payload.overlay.description)
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end

      [200, "Ticket sent to Shopify"]

    end
  end
end

module Shopify
  class Base < SupportBeeApp::Base
    oauth  :shopify, :required => true, :oauth_options => {scope:'read_products,read_orders,write_content'}
    string :shop_name, :required => true, :label => 'Enter Shop Name'

    private

    def create_blog(title, body)
      token = settings.oauth_token || settings.token
      response = http_post "https://#{settings.shop_name}.myshopify.com/admin/blogs.json" do |req|
        req.headers['X-Shopify-Access-Token'] = token
        req.headers['Content-Type'] = 'application/json'
        req.body = {blog:{title:title, body:body}}.to_json
      end
    end
  end
end

