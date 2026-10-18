defmodule Kgkm.MessagesTest do
  use Kgkm.DataCase

  alias Kgkm.Messages
  alias Kgkm.Messages.Message
  import Kgkm.ChatsFixtures
  import Kgkm.AccountsFixtures
  alias Kgkm.Chats
  alias Kgkm.Accounts.Scope


  describe "messages" do
    test "list_messages/2 respects user cleared_at timestamp" do
      user1 = user_fixture()
      user2 = user_fixture()
      chat = direct_chat_fixture(user1, user2)

      # 1. Cria a mensagem antiga
      _msg1 = message_fixture(chat, user1, %{content: "Mensagem antiga"})

      # Captura o momento exato após a primeira mensagem
      clear_time = DateTime.utc_now() |> DateTime.truncate(:second)

      # 2. Executa a limpeza e define o cleared_at para esse exato ponto no tempo
      assert {:ok, _} = Kgkm.Chats.clear_history_for_user(chat.id, user1.id)

      chat_member = Repo.get_by!(Kgkm.Chats.ChatMember, chat_id: chat.id, user_id: user1.id)
      Repo.update!(Kgkm.Chats.ChatMember.changeset(chat_member, %{cleared_at: clear_time}))

      # Pausa breve para garantir que a próxima mensagem ocorra num segundo posterior
      Process.sleep(1100)

      # 3. Cria a mensagem nova pós-limpeza
      _msg2 = message_fixture(chat, user2, %{content: "Mensagem nova"})

      # Listando as mensagens para o user1, a antiga fica antes de clear_time e é filtrada
      messages = Messages.list_messages(chat.id, user1.id)
      assert length(messages) == 1
      assert hd(messages).content == "Mensagem nova"
    end

    test "save_message/1 marks message as saved" do
      user = user_fixture()
      user2 = user_fixture()
      chat = direct_chat_fixture(user, user2)
      msg = message_fixture(chat, user)

      refute msg.is_saved

      assert {:ok, updated_msg} = Messages.save_message(msg.id)
      assert updated_msg.is_saved
    end
  end

  describe "mark_chat_messages_as_read/2" do
    setup do
      # Cria dois usuarios e um chat direto entre eles para o cenario de teste
      user1 = user_fixture()
      user2 = user_fixture()

      # Cria os scopes corretos para os usuários
      scope1 = %Scope{user: user1}
      scope2 = %Scope{user: user2}

     # Usa o scope1 para criar o chat direto
      {:ok, chat} = Chats.find_or_create_direct_chat(scope1, user2.id)

      %{user1: user1, user2: user2, scope1: scope1, scope2: scope2, chat: chat}
    end

    test "marca apenas as mensagens do outro usuario como lidas e dispara PubSub", %{user1: user1, scope1: scope1, scope2: scope2, chat: chat} do
      # Inscreve o processo atual no canal PubSub de leitura do chat para testar a notificação
      Phoenix.PubSub.subscribe(Kgkm.PubSub, "chat:#{chat.id}:read")

      # Usuario 2 envia uma mensagem para o usuario 1 usando o scope2 correto
      {:ok, msg_from_user2} = Messages.create_message(scope2, %{
        "chat_id" => chat.id,
        "content" => "Ola do user2"
      })

      # Usuário 1 envia uma mensagem para o Usuário 2 usando o scope1 correto
      {:ok, msg_from_user1} = Messages.create_message(scope1, %{
        "chat_id" => chat.id,
        "content" => "Ola do user1"
      })

      # Verifica que o status inicial de ambas é :sent
      assert Repo.get(Message, msg_from_user2.id).status == :sent
      assert Repo.get(Message, msg_from_user1.id).status == :sent

      # Usuário 1 abre o chat e marca as mensagens como lidas
      Messages.mark_chat_messages_as_read(chat.id, user1.id)

      # A mensagem enviada pelo usuário 2 agora deve estar como :read
      assert Repo.get(Message, msg_from_user2.id).status == :read

      # A mensagem enviada pelo próprio usuário 1 deve continuar como :sent (não se auto-lê)
      assert Repo.get(Message, msg_from_user1.id).status == :sent

      # Garante que o evento PubSub foi disparado corretamente
      assert_receive {:messages_read, user_id}
      assert user_id == user1.id
    end
  end
end
