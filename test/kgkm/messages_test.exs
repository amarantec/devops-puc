defmodule Kgkm.MessagesTest do
  use Kgkm.DataCase

  alias Kgkm.Messages
  import Kgkm.AccountsFixtures
  import Kgkm.ChatsFixtures

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
end
