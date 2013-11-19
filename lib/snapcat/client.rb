module Snapcat
  class Client
    attr_reader :user

    def initialize(username)
      @user = User.new
      @requestor = Requestor.new(username)
    end

    def block(username)
      @requestor.request_with_username(
        'friend',
        action: 'block',
        friend: username
      )
    end

    def clear_feed
      @requestor.request_with_username('clear')
    end

    def fetch_updates(update_timestamp = 0)
      set_user_data_with(@requestor.request_with_username(
        'updates',
        update_timestamp: update_timestamp
      ))
    end

    def media_for(snap_id)
      result = @requestor.request_media(snap_id)
      Snapcat::Media.new(result.data[:media])
    end

    def delete_friend(username)
      @requestor.request_with_username(
        'friend',
        action: 'delete',
        friend: username
      )
    end

    def set_display_name(username, display_name)
      @requestor.request_with_username(
        'friend',
        action: 'display',
        display: display_name,
        friend: username
      )
    end

    def login(password)
      set_user_data_with(
        @requestor.request_with_username('login', password: password)
      )
    end

    def logout
      @requestor.request_with_username('logout')
    end

    def register(password, birthday, email)
      result = @requestor.request(
        'register',
        birthday: birthday,
        email: email,
        password: password
      )
      unless result.success?
        return result
      end

      result_two = @requestor.request_with_username(
        'registeru',
        email: email
      )

      set_user_data_with(result_two)
    end

    def screenshot(snap_id, view_duration = 1)
      snap_data = {
        snap_id => {
          c: Status::SCREENSHOT,
          sv: view_duration,
          t: Timestamp.float
        }
      }
      events = [
        {
          eventName: 'SNAP_SCREENSHOT',
          params: { id: snap_id },
          ts: Timestamp.macro - view_duration
        }
      ]

      @requestor.request_events(events, snap_data)
    end

    def send_media(media_id, recipients, view_duration = 3)
      @requestor.request_with_username(
        'send',
        media_id: media_id,
        recipient: prepare_recipients(recipients),
        time: view_duration
      )
    end

    def unblock(username)
      @requestor.request_with_username(
        'friend',
        action: 'unblock',
        friend: username
      )
    end

    def view(snap_id, view_duration = 1)
      snap_data = {
        snap_id => { t: Timestamp.float, sv: view_duration }
      }
      events = [
        {
          eventName: 'SNAP_VIEW',
          params: { id: snap_id },
          ts: Timestamp.macro - view_duration
        },
        {
          eventName: 'SNAP_EXPIRED',
          params: { id: snap_id },
          ts: Timestamp.macro
        }
      ]

      @requestor.request_events(events, snap_data)
    end

    def upload_media(data, type = nil)
      @requestor.request_upload(data, type)
    end

    def update_email(email)
      @requestor.request_with_username(
        'settings',
        action: 'updateEmail',
        email: email
      )
    end

    def update_privacy(code)
      @requestor.request_with_username(
        'settings',
        action: 'updatePrivacy',
        privacySetting: code
      )
    end

    private

    def prepare_recipients(recipients)
      if recipients.is_a? Array
        recipients.join(',')
      else
        recipients
      end
    end

    def set_user_data_with(result)
      if result.success?
        @user.data = result.data
      end

      result
    end
  end
end
