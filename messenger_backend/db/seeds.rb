# Limpa o banco de dados antes de começar para não duplicar usuários
Message.destroy_all
User.destroy_all

# Criando 2 usuários de teste
# .create! com exclamação serve para avisar se houver erro na criação
alice = User.create!(name: "Alice")
bob = User.create!(name: "Bob")

# Criando uma mensagem inicial entre eles
Message.create!(
  sender: alice, 
  recipient: bob, 
  content: "Oi Bob, tudo bem?"
)

puts "Sucesso! Criamos Alice, Bob e 1 mensagem de teste."