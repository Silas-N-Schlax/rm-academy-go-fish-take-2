# User class
class User
  attr_accessor :client, :id, :name, :name_message

  def initialize(client, id)
    @client = client
    @id = id
  end
end
