#!/usr/bin/ruby


require 'rubygems'
require 'net/http'
require 'rexml/document'
require 'fox16'
include Fox


Npr = Struct.new(:npr_title, :npr_link)

Slash = Struct.new(:slash_title, :slash_link)

class RssViewer < FXMainWindow
	def initialize(app)
		super( app,'RssViewer', :width => 568, :height => 780)

		$npr_list = []
		$slash_list = []

		x = Thread.new {Thread.stop}


		frame = FXVerticalFrame.new( self )

		t_frame = FXHorizontalFrame.new(frame)

		FXLabel.new(t_frame, "NPR news...   ")

		@da_news_text_npr = FXList.new(frame,:opts =>LAYOUT_FIX_WIDTH |
		LAYOUT_FIX_HEIGHT, :width =>560, :height =>300)
		
		s_frame = FXHorizontalFrame.new(frame)

		FXLabel.new(s_frame, "Slashdot news...")

		@da_news_text_slashdot = FXList.new(frame,:opts =>LAYOUT_FIX_WIDTH |
		LAYOUT_FIX_HEIGHT, :width =>560, :height =>300)

		h_frame = FXHorizontalFrame.new(frame)
		
		@update = FXButton.new(h_frame, "Update the news")
			@update.connect(SEL_COMMAND) do |sender, selector, data|
				@da_news_text_npr.clearItems
				@da_news_text_slashdot.clearItems
				$npr_list.clear
				$slash_list.clear
				if FileTest.exist?("npr_temp")
				then
					File.delete("npr_temp")
				end
				http = Net::HTTP.new 'www.npr.org'
				http.open_timeout = 30
				http.start
				raise "Connection failed" unless http
				response = http.get('/rss/rss.php?id=1001')
				myxml = REXML::Document.new response.body
				myxml.each_element('rss/channel/item') do |elem| 
					File.open("npr_temp", "a") do |a|
						a.puts elem.elements['title'].text
					end
					title = elem.elements['title'].text
					link = elem.elements['link'].text

					@npr_els = Npr.new(title, link)
					$npr_list.push(@npr_els)
			end	
				file = File.open("npr_temp", "r")
					while (line = file.gets)
						npr_title = line.chop!
						@da_news_text_npr.appendItem(FXListItem.new(npr_title.to_s))
					end
			
				
				if FileTest.exist?("slash_temp")
				then
					File.delete("slash_temp")
				end

				#@da_news_text_slashdot.text = ""
				http = Net::HTTP.new 'rss.slashdot.org'
				http.open_timeout = 30
				http.start
				raise "Connection failed" unless http
				response = http.get('/Slashdot/slashdot')
				myxml = REXML::Document.new response.body
				myxml.each_element('rdf:RDF/item') do |elem| 
					File.open("slash_temp", "a") do |a|
						a.puts elem.elements['title'].text
					end
						title = elem.elements['title'].text
						link = elem.elements['link'].text

						@slash_els = Slash.new(title,link)
						$slash_list.push(@slash_els)
				end
						
				i = 0
				newfile = File.open("slash_temp", "r")
					while (line = newfile.gets)
						@slash_title = line.chop
						@da_news_text_slashdot.appendItem(FXListItem.new(@slash_title.to_s))
					end
				end


			

				@da_news_text_npr.connect(SEL_DOUBLECLICKED) do |sender,selector,data|
				if x.alive?
					x.kill
				end
				i = 0
					@da_news_text_npr.each do |a|
						$npr_list.each do |b|
							linkString = a.to_s
							if @da_news_text_npr.itemSelected?(i) and 
							linkString == b.npr_title
								
								puts "Working here"
								x = Thread.new {
								system("firefox #{b.npr_link} > /dev/null")

					  		}
							end
						end
						i+=1
					end
				end

		@da_news_text_slashdot.connect(SEL_DOUBLECLICKED) do |sender,selector,data|
				if x.alive?
					x.kill
				end
				i = 0
					@da_news_text_slashdot.each do |a|
						$slash_list.each do |b|
							linkString = a.to_s
							if @da_news_text_slashdot.itemSelected?(i) and 
							linkString == b.slash_title
								
								puts "Working here"
								x = Thread.new {
								system("firefox #{b.slash_link} > /dev/null")

					  		}
							end
						end
						i+=1
					end
				end
	end
end

if __FILE__ == $0
	
	app = FXApp.new('RssViewer')
	win = RssViewer.new(app)

	app.create
	win.show
	app.run
end
