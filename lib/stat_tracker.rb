require 'csv'
require_relative 'game'
require_relative 'team'
require 'pry'
require_relative 'game_team'
require_relative 'team_stats'
require_relative 'game_stats'
require_relative 'game_team_stats'

class StatTracker
  include TeamStats, GameStats, GameTeamStats

  attr_accessor :teams,
                :games

  attr_reader :game_teams,
              :team_stats

  def initialize(info_hash)
    @games = []
    game_instance(info_hash[:games])
    @teams = []
    team_instance(info_hash[:teams])
    assign_percentages_to_teams
    @game_teams = []
    game_team_instance(info_hash[:game_teams])
  end

  def self.from_csv(data) ###### maybe load the csvs to local variables??
    StatTracker.new(data)
  end

 ####################### Instance Creation###########################

  def game_instance(game_file)
    CSV.foreach(game_file, headers: true, header_converters: :symbol) do |row|
      @games << Game.new(row)
    end
  end

  def team_instance(team_file)
    CSV.foreach(team_file, headers: true, header_converters: :symbol) do |row|
      team = Team.new(row)
      @teams << team
    end
  end

  def games_by_team_instance(team)
    team.team_id
  end

  def game_team_instance(game_team_file)
    CSV.foreach(game_team_file, headers: true, header_converters: :symbol) do |row|
      @game_teams << GameTeam.new(row)
    end
  end

  # def team_info(id)
  #   @team_stats.get_team_info(id)
  # end

#################################GAME ANALYTICS FOR ALL GAMES FOR ALL TEAMS#############


  def highest_total_score
    max_game = @games.max_by do |game|
      game.total_score
    end
    max_game.total_score
  end

  def percentage_home_wins
    games_won_by_home = games.find_all do |game|
      game.outcome[0..3] == "home"
    end
    (games_won_by_home.count.to_f / games.count * 100).round(2)
  end

  def average_goals_per_game
    total_goals = @games.inject(0) do |sum, game|
      sum + game.total_score
    end
    (total_goals.to_f/@games.length.to_f).round(2)
  end

  def all_games_by_season
    @games.group_by do |game|
      game.season
    end
  end

  def average_goals_by_season
    average_by_season = {}
    all_games_by_season.each do |season, games|
      total_score_for_season = games.inject(0) do |sum, game|
        sum + game.total_score
      end
      average_by_season[season] = (total_score_for_season.to_f/games.flatten.count).round(2)
    end
    average_by_season
  end

  def lowest_total_score
    min_game = @games.min_by do |game|
      game.total_score
    end
    min_game.total_score
  end

  def biggest_blowout
    blowout_game = @games.max_by do |game|
      game.score_difference
    end
    blowout_game.score_difference
  end

##########################GAME ANALYTICS FOR ALL TEAMS AT HOME###################

  def percentage_home_wins
    games_won_by_home = games.find_all do |game|
      game.outcome[0..3] == "home"
    end
    (games_won_by_home.count.to_f / games.count * 100).round(2)
  end

#############################TEAM ANALYTICS#######################

  def team_info(id)
    found_team = @teams.find do |team|
      team.team_id == id
    end
    team_hash = Hash.new
    team_hash[id] = found_team.provide_info
  end


############################GAME ANALYTICS HELPER METHODS#########################

  def games_by_season
    @games.group_by do |game|
      game.season
    end
  end

  def preseason_games
    @games.find_all do |game|
      game.type == "P"
    end
  end

  def reg_season_games
    @games.find_all do |game|
      game.type == "R"
    end
  end



  def most_popular_venue
    most_popular = game_count_by_venue.max_by do |venue_count|
      venue_count.last
    end
    return most_popular.first
  end

  def least_popular_venue
    least_popular = game_count_by_venue.min_by do |venue_count|
      venue_count.last
    end
    return least_popular.first
  end

############ HELPER METHOD FOR THE VENUE METHODS

  def game_count_by_venue
    venue_events = @games.group_by do |game|
      game.venue
    end
    venue_events.map do |venue, games|
      [venue, games.count]
    end
  end

  def count_of_games_by_season
    game_count_by_season = {}
    all_games_by_season.each do |season, games|
      game_count_by_season[season] = games.count
    end
    return game_count_by_season
  end

  def season_with_most_games
    highest_count = count_of_games_by_season.values.max
    count_of_games_by_season.key(highest_count).to_i
  end

  def season_with_fewest_games
    lowest_count = count_of_games_by_season.values.min
    count_of_games_by_season.key(lowest_count).to_i
  end

  def percentage_visitor_wins
    games_won_by_visitor = games.find_all do |game|
      game.outcome[0..3] == "away"
    end
    (games_won_by_visitor.count.to_f / games.count * 100).round(2)
  end

  def lowest_scoring_visitor
    lowest_scoring_away_team = teams.min_by do |team|
      if team.games_played_as_visitor(games) != 0
        team.total_away_points(games).to_f / team.games_played_as_visitor(games)
      else
        100
      end
    end
    lowest_scoring_away_team.team_name
  end

  def lowest_scoring_home_team
    lowest_scoring_home_team = teams.min_by do |team|
      if team.games_played_as_home_team(games) != 0
        team.total_home_points(games).to_f / team.games_played_as_home_team(games)
      else
        100
      end
    end
    lowest_scoring_home_team.team_name
  end

  def highest_scoring_home_team
    highest_scoring_home_team = teams.max_by do |team|
      if team.games_played_as_home_team(games) != 0
        team.total_home_points(games).to_f / team.games_played_as_home_team(games)
      else
        0
      end
    end
    highest_scoring_home_team.team_name
  end

  def highest_scoring_visitor
    highest_scoring_away_team = teams.max_by do |team|
      if team.games_played_as_visitor(games) != 0
        team.total_away_points(games).to_f / team.games_played_as_visitor(games)
      else
        0
      end
    end
    highest_scoring_away_team.team_name
  end

  def winningest_team
    team_with_highest_win_percentage = @teams.max_by do |team|
      team.number_of_games_won(games).to_f / team.games_played_in(games).count
    end
    team_with_highest_win_percentage.team_name
  end

  def biggest_bust(season_id)
    preseason = []
    reg_season = []
    @games.each do |game| # could this be a method?
      if season_id == game.season && game.type == "P"
        preseason << game
      elsif season_id == game.season && game.type == "R"
        reg_season << game
      end
    end
    largest_decrease_in_percentage = @teams.max_by do |team|
      total_preseason_wins = preseason.inject(0) do |wins, game| # method
        if team.team_id == game.away_team_id && game.outcome.include?("away")
          wins + 1
        elsif team.team_id == game.home_team_id && game.outcome.include?("home")
          wins + 1
        else
          wins
        end
      end
      total_preseason_games_played = preseason.inject(0) do |total_played, game| # method
        if team.team_id == game.away_team_id || team.team_id == game.home_team_id
          total_played + 1
        else
          total_played
        end
      end
      preseason_win_percentage = total_preseason_wins.to_f / total_preseason_games_played
      total_reg_season_wins = reg_season.inject(0) do |wins, game| # method
        if team.team_id == game.away_team_id && game.outcome.include?("away")
          wins + 1
        elsif team.team_id == game.home_team_id && game.outcome.include?("home")
          wins + 1
        else
          wins
        end
      end
      total_reg_season_games_played = reg_season.inject(0) do |total_played, game| # method
        if team.team_id == game.away_team_id || team.team_id == game.home_team_id
          total_played + 1
        else
          total_played
        end
      end
      reg_season_win_percentage = total_reg_season_wins.to_f / total_reg_season_games_played
      if reg_season_win_percentage != 0.0
        preseason_win_percentage/reg_season_win_percentage
      elsif preseason_win_percentage != 0.0
        100.0
      else
        1.0
      end
    end
    largest_decrease_in_percentage.team_name
  end

  def biggest_surprise(season_id)
    preseason = []
    reg_season = []
    @games.each do |game| # method
      if season_id == game.season && game.type == "P"
        preseason << game
      elsif season_id == game.season && game.type == "R"
        reg_season << game
      end
    end
    largest_increase_in_percentage = @teams.max_by do |team| #THIS is the real method
      total_preseason_wins = preseason.inject(0) do |wins, game| # separate method
        if team.team_id == game.away_team_id && game.outcome.include?("away")
          wins + 1
        elsif team.team_id == game.home_team_id && game.outcome.include?("home")
          wins + 1
        else
          wins
        end
      end
      total_preseason_games_played = preseason.inject(0) do |total_played, game| # separate method
        if team.team_id == game.away_team_id || team.team_id == game.home_team_id
          total_played + 1
        else
          total_played
        end
      end
      preseason_win_percentage = total_preseason_wins.to_f / total_preseason_games_played # method
      total_reg_season_wins = reg_season.inject(0) do |wins, game| # method
        if team.team_id == game.away_team_id && game.outcome.include?("away")
          wins + 1
        elsif team.team_id == game.home_team_id && game.outcome.include?("home")
          wins + 1
        else
          wins
        end
      end
      total_reg_season_games_played = reg_season.inject(0) do |total_played, game| # method
        if team.team_id == game.away_team_id || team.team_id == game.home_team_id
          total_played + 1
        else
          total_played
        end
      end
      reg_season_win_percentage = total_reg_season_wins.to_f / total_reg_season_games_played
      if preseason_win_percentage != 0.0
        reg_season_win_percentage/preseason_win_percentage
      elsif reg_season_win_percentage != 0.0
        100.0
      else
        1.0
      end
    end
    largest_increase_in_percentage.team_name
  end

  #
  # def season_summary(season_id, team_id)
    # team method that returns preseason summary hash (preseason_summary)
    # {team method for preseason_win_percentage
    # team method for preseason_goals_scored
    # team method for preseason_goals_against}
    # same thing for reg season (reg_season_summary)
    # hash with preseason summary hash and regular season summary hash

  def home_win_percentages(team_id, games)
    games_played_at_home = games.select do |game|
      game.home_team_id == team_id
    end

    games_won_at_home =  games_played_at_home.count do |game|
      game.outcome.include?("home")
    end
    if games_played_at_home.length != 0
      return (games_won_at_home.to_f / games_played_at_home.length) * 100.0
    else
      return 0.0
    end
  end

  def away_win_percentages(team_id, games)
    games_played_away = games.select do |game|
      game.away_team_id == team_id
    end

    games_won_away =  games_played_away.count do |game|
      game.outcome.include?("away")
    end

    if games_played_away.length != 0
      return (games_won_away.to_f / games_played_away.length) * 100.0
    else
      return 0.0
    end
  end


  def home_win_percentage_per_team
    home_win_percentage = Hash.new(0)

    games_played_at_home_per_team = @games.group_by do |game|
      game.home_team_id
    end

    games_played_at_home_per_team.each do |home_team_id, games|
      home_win_percentage[home_team_id] = home_win_percentages(home_team_id, games)
    end
    home_win_percentage

  end

  # def games_by_teams_location(home_or_away)
  #
  #   @teams.each do |team|
  #     if
  #   games_by_location = @games.group_by do |game|
  #     if team_id == game.away_team_id
  #       game.away_team_id
  #     elsif team_id == game.home_team_id
  #       game.home_team_id
  #     end
  #     games_by_location
  # end
  #
  # end

  def away_win_percentage_per_team
    away_win_percentage = Hash.new(0)
    games_played_away_per_team = @games.group_by do |game|
      game.away_team_id
    end

    games_played_away_per_team.each do |away_team_id, games|
      away_win_percentage[away_team_id] = away_win_percentages(away_team_id,games)
    end
    away_win_percentage
  end

  def assign_percentages_to_teams
    @teams.each do |team|
      team.away_win_percentage = away_win_percentage_per_team[team.team_id]
    end

    @teams.each do |team|
      team.home_win_percentage = home_win_percentage_per_team[team.team_id]
    end
  end

  def best_fans
    best_fans_team = @teams.max_by do |team|
      team.home_win_percentage - team.away_win_percentage
    end
    best_fans_team.team_name
  end

  def worst_fans
    worst_fans_teams = @teams.select do |team|
      team.away_win_percentage > team.home_win_percentage
    end

    worst_fans_teams.map do |team|
      team.team_name
    end
  end


  def games_by_season_type(season_id, team_id)


    games_by_type_of_season = Hash.new
    games_in_season = games_by_season[season_id]


    preseason = games_in_season.select do |game|
      game.type == "P"
    end

    regular_season = games_in_season.select do |game|
      game.type == "R"
    end

    games_by_type_of_season[:preseason] = preseason
    games_by_type_of_season[:regular_season] = regular_season

    games_by_type_of_season[:preseason].delete_if do |game|
      game.away_team_id != team_id && game.home_team_id != team_id
    end

    games_by_type_of_season[:regular_season].delete_if do |game|
      game.away_team_id != team_id && game.home_team_id != team_id
    end

    games_by_type_of_season

  end

  def goals_scored(team_id,games)
    goals = 0
    games.each do |game|
      if game.away_team_id == team_id
        goals =+ game.away_goals
      else
        goals += game.home_goals
      end
    end
    goals
  end

# def season_summary(season_id, team_id)
#   summary = {}
#   by_season_type_for_given_team = games_by_season_type(season_id, team_id)
#   preseason_stats = {}
#   regular_season_stats = {}
#
#   preseason_games = by_season_type_for_given_team[:preseason]
#   regular_games = by_season_type_for_given_team[:regular_season]
#
#   preseason_wins = win_percentage(team_id, preseason_games)
#   regular_wins = win_percentage(team_id, regular_games)
#
#   preseason_goals = goals_scored(team_id, preseason_games)
#   regular_goals = goals_scored(team_id,regular_games)
#
#   preseason_stats[:win_percentage] = preseason_wins
#   preseason_stats[:goals_scored] = preseason_goals
#
#   regular_season_stats[:win_percentage] = regular_wins
#   regular_season_stats[:goals_scored] = regular_goals
#
#   summary[:preseason] = preseason_stats
#   summary[:regular_season] = regular_season_stats
#
#   summary
# end

  def count_of_teams
    @teams.count
  end

  def games_by_all_team_ids
    @game_teams.group_by do |game_team|
      game_team.team_id
    end
  end

  def games_by_team_id(team_id)
    games_by_all_team_ids[team_id]
  end

  def team_total_score(team_id)
    games_by_team_id(team_id).sum do |game|
      game.goals.to_i
    end
  end

  def game_count_by_team_id(team_id)
    games_by_team_id(team_id).count
  end

  def average_score_by_team_id(team_id)
    team_total_score(team_id).to_f / game_count_by_team_id(team_id).to_f
  end

  def best_offense_by_team_name
    best_team = @teams.max_by do |team|
      average_score_by_team_id(team.team_id)
    end
    return best_team.team_name
  end

  def worst_offense_by_team_name
    worst_team = @teams.min_by do |team|
      average_score_by_team_id(team.team_id)
    end
    return worst_team.team_name
  end

  def get_opponent_team_game_ids(team_id)
    games_by_team_id(team_id).map do |g_t|
      g_t.game_id
    end
  end

  def get_opponent_game_teams(team_id)
    get_opponent_team_game_ids(team_id).map do |game_id|
      game_teams.find do |g_t|
        g_t.game_id == game_id && g_t.team_id != team_id
      end
    end
  end

  def team_opponent_goals(team_id)
    get_opponent_game_teams(team_id).sum do |g_t|
      g_t.goals.to_i
    end
  end

  def all_teams_opponent_averages
    all_teams = {}

    @teams.each do |team|
      all_teams[team.team_id] = (team_opponent_goals(team.team_id))/game_count_by_team_id(team.team_id).to_f
    end

    all_teams
  end

  def get_team_name_from_id(team_id)
    team_name = nil

    @teams.each do |team|
      if team.team_id == team_id
        team_name = team.team_name
      end
    end

    team_name
  end

  def best_defense
    team_id = all_teams_opponent_averages.key(all_teams_opponent_averages.values.min)
    get_team_name_from_id(team_id)
  end

  def worst_defense
    team_id = all_teams_opponent_averages.key(all_teams_opponent_averages.values.max)
    get_team_name_from_id(team_id)
  end
end
