require "yaml"

WORD_FILE = File.expand_path("../5desk.txt", File.dirname(__FILE__))
SAVE_FILE = File.expand_path("../hangman_save.yml", File.dirname(__FILE__))

class InvalidResponseError < RuntimeError; end

class Hangman	
	def initialize(word = nil, num_guesses = 6, display = nil)		
		word ||= choose_word(WORD_FILE)
		@word = word
		
		@guesses = num_guesses
		
		display ||= Array.new(@word.length) { |i| i = "_" }
		@display = display
	end
	
	def play
		loop do
			render_display
			
			guess = player_guess
			
			if guess == "save"
				save_and_quit
			elsif correct_guess?(guess)
				update_display(guess)
			else
				@guesses -= 1
			end
			
			break if player_won? || @guesses < 1
		end
		
		if player_won?
			puts "Congratulations, you got it!"
		else
			puts "Sorry, you're out of guesses!"
		end
		
		complete_word
		render_display
	end
	
	private
	
	def choose_word(filename)
		File.open(filename) do |f|
			f.seek(0)
			words = f.readlines.select { |word| word.chomp.length > 4 && word.chomp.length < 12 }

			words.sample.chomp
		end
	end
	
	def complete_word
		@display.each_index { |i| @display[i] = @word[i] }
	end
	
	def correct_guess?(guess)
		@word.include?(guess)
	end
	
	def display_word
		puts @display.join(" ")
	end
	
	def player_choice
		response = user_prompt("Make a guess or save and quit?", ["guess", "save"])
	end
	
	def player_guess
		begin
			print "Please guess a letter or enter 'save' to save and quit: "
			
			guess = gets.chomp.downcase
			
			if !valid_guess?(guess)
				raise InvalidResponseError.new("Sorry, that's not a valid guess.")
			elsif @display.include?(guess)
				raise InvalidResponseError.new("You already guessed that letter!")
			end
		rescue InvalidResponseError => err
			puts err.message
			print "\n"
			retry
		end
		
		guess
	end
	
	def player_won?
		@display.join == @word
	end
	
	def render_display
		puts "Guesses remaining: " << @guesses.to_s
		puts "\n"
		puts @display.join(" ")
	end
	
	def save_and_quit
		File.open(SAVE_FILE, "w+") do |f|
			f.seek(0)
			f.puts YAML::dump({ :word => @word, :num_guesses => @guesses, :display => @display })
		end
		
		exit
	end
	
	def update_display(guess)
		indices = @word.split("").each_index.select do |i|  
			@word[i] == guess
		end
		
		indices.each { |i| @display[i] = guess }
	end
	
	def valid_guess?(guess)
		guess == "save" || (guess.length == 1 && guess.index(/[^a-z]/).nil?)
	end
end

def user_prompt(query, responses, errmsg = "Sorry, I didn't understand that.  Please try again.")
		
	if block_given? && responses.class == String 
		response_str = responses
	else
		response_str = responses.map { |resp| "'#{resp.to_s.downcase}'" }
		
		if response_str.length < 3
			join_chr = " or "
		else
			join_chr = ", "
		end
	
		response_str = response_str.join(join_chr)
	end
	
	begin
		puts query
		print "Enter #{response_str}: "
		
		option = gets.strip.downcase
		
		if block_given?
			raise InvalidResponseError.new(errmsg) unless yield option
		else
			raise InvalidResponseError.new(errmsg) unless responses.include?(option)
		end
	rescue InvalidResponseError => err
		puts err.message
		puts "\n"
		retry
	end
	
	option
end

def load_game(filename)
	game_data = YAML.load_file(filename)
end

loop do
	system "clear" or system "cls"
	option = user_prompt("Do you want to load your game or start a new game?", \
											["new", "load"])
											
	if option == "new"
		game = Hangman.new
	else
		game_data = load_game(SAVE_FILE)
		game = Hangman.new(game_data[:word], game_data[:num_guesses], game_data[:display])
	end
	
	game.play
	
	play_again = user_prompt("Play again?", ["y", "n"])
	break if play_again == "n"	
end