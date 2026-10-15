defmodule Kgkm.ChatsTest do
  use Kgkm.DataCase

  alias Kgkm.Chats
  alias Kgkm.Chats.ChatMember

  import Kgkm.AccountsFixtures
  import Kgkm.ChatsFixtures

  describe "chats" do
    test "list_user_chats/1 returns only chats where user is member and not hidden" do
      user1 = user_fixture()
      user2 = user_fixture()
      user3 = user_fixture()

      chat1 = direct_chat_fixture(user1, user2)
      _chat2 = direct_chat_fixture(user1, user3)

      scope = %Kgkm.Accounts.Scope{user: user1}
      chats = Chats.list_user_chats(scope)

      # Deve retornar os 2 chats inicialmente
      assert length(chats) == 2

      # Oculta o chat1 para o user1
      assert {:ok, _} = Chats.hide_chat_for_user(chat1.id, user1.id)

      # Agora deve retornar apenas 1
      chats_after_hide = Chats.list_user_chats(scope)
      assert length(chats_after_hide) == 1
    end

    test "toggle_mute_participant/2 switches the mute status individually" do
      user1 = user_fixture()
      user2 = user_fixture()
      chat = direct_chat_fixture(user1, user2)

      member_before = Repo.get_by!(ChatMember, chat_id: chat.id, user_id: user1.id)
      refute member_before.is_muted?

      # Mutar
      assert {:ok, _} = Chats.toggle_mute_participant(chat.id, user1.id)
      member_muted = Repo.get_by!(ChatMember, chat_id: chat.id, user_id: user1.id)
      assert member_muted.is_muted?

      # Desmutar
      assert {:ok, _} = Chats.toggle_mute_participant(chat.id, user1.id)
      member_unmuted = Repo.get_by!(ChatMember, chat_id: chat.id, user_id: user1.id)
      refute member_unmuted.is_muted?
    end

    test "clear_history_for_user/2 sets cleared_at timestamp" do
      user1 = user_fixture()
      user2 = user_fixture()
      chat = direct_chat_fixture(user1, user2)

      assert {:ok, _} = Chats.clear_history_for_user(chat.id, user1.id)

      member = Repo.get_by!(ChatMember, chat_id: chat.id, user_id: user1.id)
      assert member.cleared_at != nil
    end
  end
end
