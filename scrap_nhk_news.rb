# -*- coding: utf-8 -*-

require "nokogiri"
require "open-uri"

Plugin.create(:scrap_nhk_news) do
    @ELEMENT_TITLE = 'span.contentTitle'
    @ELEMENT_MAIN = 'p#news_textbody,p#news_textmore'
    @ELEMENT_ADD = 'div.news_add *'
    @MESSAGE_SELECTORS = [@ELEMENT_MAIN, @ELEMENT_ADD]

    filter_rebuild_message do |message|
        dummy_message = message
        if message.user === 'nhk_news' then
            begin
                dummy_text = get_contents(message)
                dummy_message = Message.new(
                    :id => message[:id],
                    :message => dummy_text,
                    :user => message[:user],
                    :receiver => message[:receiver],
                    :replyto => message[:replyto],
                    :source => message[:source],
                    :geo => message[:geo],
                    :exact => message[:exact],
                    :created => message[:created],
                    :modified => message[:modified],
                    :system => true)
            rescue => e
                p e.backtrace.join("\n")
            end
        end
        [dummy_message]
    end

    # コンテンツ抽出と
    # メッセージ詰め込み
    def get_contents(message)
        url = URI.extract(message.to_s)[0]
        doc = Nokogiri::HTML(open(url))

        text = "■ #{doc.css(@ELEMENT_TITLE)[0].text}\n"

        for message_selector in @MESSAGE_SELECTORS do
            elements = doc.css(message_selector)

            # 取得した要素に応じてテキスト変換
            for element in elements do
                if element.name == 'h3' then
                    text += "・#{element.text}\n"
                else
                    text += "　#{element.text}\n"
                end
            end
        end

        return text
    end
end
