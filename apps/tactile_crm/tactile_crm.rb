module TactileCrm
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
      ticket = payload.ticket
      requester = ticket.requester
      person = find_person(requester)
      if person
        html = existing_person_info(person)
      else
        person = create_person(requester)
        html = created_person_info(person)
      end
      update_note(person, ticket)
      comment_on_ticket(html, ticket)
      [200, "Ticket sent"]
    end
  end
end

module TactileCrm
  module ActionHandler
    def button
     # Handle Action here
     [200, "Success"]
    end
  end
end

module TactileCrm
  class Base < SupportBeeApp::Base
    string :api_token, :required => true, :label => 'Tactile Auth Token'
    string :account_name, :required => true, :label => 'Tactile Account Name'
    boolean :should_create_person, :default => true, :required => false, :label => 'Create a New Person'
	
    white_list :account_name, :should_create_person
    
    def find_person(requester)
      first_name, sur_name = split_name(requester)
      response = http.get "https://#{settings.account_name}.tactilecrm.com/people" do |req|
        req.headers['Accept'] = 'application/json'
        req.params['api_token'] = settings.api_token
      end
      people = response.body['people']
      person = people.select{|pe| pe['firstname'] == first_name and pe['email'] == requester.email}.first
      if person
        puts person
        return person
      else
        return nil
      end
      
    end

    def create_person(requester)
      return unless settings.should_create_person.to_s == '1'
      first_name, sur_name = split_name(requester)
      response = http_post "https://#{settings.account_name}.tactilecrm.com/people/save" do |req|
        req.headers['Content-Type'] = 'application/json'
        req.params['api_token'] = settings.api_token
        req.body = {Person:{firstname:first_name, surname:first_name}}.to_json
      end
      person_id = response.body['id']
      person = get_person_by_id(person_id) 
      return person
    end

    def split_name(requester)
      first_name, sur_name = requester.name ? requester.name.split : [requester.email,'']
    end

    def get_person_by_id(person_id)
      response = http_get "https://#{settings.account_name}.tactilecrm.com/people/view/#{person_id}" do |req|
        req.headers['Content-Type'] = 'application/json'
        req.params['api_token'] = settings.api_token
      end
      person = response.body['person']
    end

    def update_note(person, ticket)
      http_post "https://#{settings.account_name}.tactilecrm.com/notes/save" do |req|
      req.headers['Content-Type'] = 'application/json'
      req.params['api_token'] = settings.api_token
      req.body = {Note:{title:'ticket address', note:generate_note_content(ticket), person_id:person['id']}}.to_json
      end
    end

    def comment_on_ticket(html, ticket)
      ticket.comment(:html => html)
    end
 
    def existing_person_info(person)
      html = ""
      html << person_link(person)
      html
    end

    def created_person_info(person)
      html = "Added <b> #{person['firstname']} </b> to Tactile... " 
      html << person_link(person)
      html
    end
    
    def person_link(person)
      "<a href='https://#{settings.account_name}.tactilecrm.com/person/view/#{person['id']}'>View #{person['name']}'s profile on Tactile</a>"
    end

    def generate_note_content(ticket)
      note = "https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}"
    end

  end
end


