require 'sqlite3'
require 'telegram/bot'

$db = SQLite3::Database.open '256.db'

$token = File.read 'bot.token'
$group = File.read 'group.id'

def run_group(bot, message)
  if message.new_chat_members != [] then
     num_members = 0
     $db.execute('SELECT COUNT(*) FROM members') do |count|
       num_members = count.first
     end

     message.new_chat_members.each do |member|
       if num_members < 256
         $db.execute('INSERT INTO members (user_id, first_name) VALUES (?, ?)', member.id, member.first_name)
         num_members += 1
       else
         bot.api.kick_chat_member(chat_id: $group, user_id: member.id)
       end
     end
  elsif message.text
    case message.text
    when /^\/sell(@.*)? (\$)?([0-9]+)/
      price = $3
      $db.execute('DELETE FROM offers WHERE user_id = ?', message.from.id)
      $db.execute('INSERT INTO offers (user_id, price) VALUES (?, ?)', [message.from.id, price])
      bot.api.send_message(chat_id: $group, text: 'Success!')
    end
  end
end

def run_dm(bot, message)
  case message
  when Telegram::Bot::Types::Message
    case message.text
    when '/start'
      bot.api.send_message(chat_id: message.chat.id, text: 'Type "/offers" to view offers for seats')
    when '/offers'
      offers = []
      $db.execute('SELECT offers.user_id, members.first_name, offers.price FROM offers INNER JOIN members ON members.user_id = offers.user_id') do |offer|
        user_id, first_name, price = offer
        offers << Telegram::Bot::Types::InlineKeyboardButton.new(text: "#{first_name}'s seat - $#{price}", callback_data: user_id)
      end
      kb = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: offers)
      bot.api.send_message(chat_id: message.chat.id, text: 'Pick an offer', reply_markup: kb)
    end
  when Telegram::Bot::Types::CallbackQuery
    user_id = message.data

    price = nil
    $db.execute('SELECT price FROM offers WHERE user_id = ?', user_id) do |offer|
      price = offer.first
    end

    unless offer.nil?
      # TODO: Payment processing
      begin
        bot.api.kick_chat_member(chat_id: $group, user_id: user_id)

        $db.execute('DELETE FROM offers WHERE user_id = ?', user_id)

        invite = bot.api.export_chat_invite_link(chat_id: $group)
        bot.api.send_message(chat_id: message.from.id, text: invite)
      rescue
        bot.api.send_message(chat_id: message.from.id, text: "Problem processing your request...")
      end
    end
  end
end

Telegram::Bot::Client.run($token) do |bot|
  bot.listen do |message|
    case message
    when Telegram::Bot::Types::Message
      if message.chat.id.to_s == $group then
        run_group(bot, message)
      else
        run_dm(bot, message)
      end
    when Telegram::Bot::Types::CallbackQuery
      run_dm(bot, message)
    end
  end
end
