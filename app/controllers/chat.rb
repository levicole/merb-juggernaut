class Chat < Application

  # ...and remember, everything returned from an action
  # goes to the client...
  def index
    render
  end
  
  def chat_message
    @data = "$('#messages').append('<li>#{params[:message]}</li>')"
    Juggernaut.send_to_all(@data)
    #merb freaks out because Juggernaut.send_to_all() returns nil.  So I am just returning an empty string
    return ""
  end
  
end
