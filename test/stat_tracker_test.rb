require './test/test_helper'
require 'minitest/autorun'
require 'minitest/pride'
require './lib/stat_tracker'
require 'pry'

class StatTrackerTest < Minitest::Test

  def setup
    game_path = './data/test_game.csv'
    team_path = './data/test_team.csv'
    game_teams_path = './data/test_game_teams_stats.csv'

    @locations = {
     games: game_path,
     teams: team_path,
     game_teams: game_teams_path
    }

    @stat_tracker = StatTracker.from_csv(@locations)

  end

  def test_it_exists

    assert_instance_of StatTracker, @stat_tracker
  end

  def test_it_creates_games_off_csv
    assert_instance_of Game, @stat_tracker.games[0]
    assert_equal 8, @stat_tracker.games.count
  end

  def test_it_can_calculate_highest_total_score
    assert_equal 7, @stat_tracker.highest_total_score
  end

  def test_it_creates_teams_off_csv
    assert_instance_of Team, @stat_tracker.teams[0]
    assert_equal 4, @stat_tracker.teams.count
  end

  def test_it_can_calculate_percentage_of_games_won_by_home_team
    assert_equal 50.0, @stat_tracker.percentage_home_wins
  end

  def test_it_can_calculate_percentage_of_games_won_by_away_team
    assert_equal 50.0, @stat_tracker.percentage_visitor_wins
  end

  def test_it_provides_team_info_from_team_id
    expected = {
                franchise_id: "10",
                short_name: "NY Rangers",
                team_name: "Rangers",
                abbreviation: "NYR",
                link: "/api/v1/teams/3"
    }


    assert_equal expected, @stat_tracker.team_info("3")
  end

  def test_it_can_calculate_average_goals_per_game
    assert_equal 5.0, @stat_tracker.average_goals_per_game
  end

  def test_it_can_calculate_average_goals_by_season
    expected = {"20122013" => 5.5, "20152016" => 4.5}
    assert_equal expected, @stat_tracker.average_goals_by_season
  end

  def test_it_calculates_lowest_total_score
    assert_equal 1, @stat_tracker.lowest_total_score
  end

  def test_it_finds_biggest_blowout
    assert_equal 3, @stat_tracker.biggest_blowout
  end

  def test_it_gets_game_count_by_venue
    expected = [["TD Garden", 2], ["Madison Square Garden", 2], ["Scottrade Center", 2], ["United Center", 2]]

    assert_equal expected, @stat_tracker.game_count_by_venue
  end

  def test_it_gets_venue_with_most_games
    skip
    assert_equal "TD Garden", @stat_tracker.most_popular_venue
  end

  def test_it_gets_venue_with_fewest_games
    skip
    assert_equal "CONSOL Energy Center", @stat_tracker.least_popular_venue
  end

  def test_it_gets_game_count_by_season
    expected = { "20122013" => 4, "20152016" => 4}

    assert_equal expected, @stat_tracker.count_of_games_by_season
  end

  def test_it_gets_season_with_most_games
    skip
    assert_equal 20122013, @stat_tracker.season_with_most_games
  end

  def test_it_gets_season_with_fewest_games
    skip
    assert_equal 20132014, @stat_tracker.season_with_fewest_games
  end

  def test_it_gets_games_by_season
    expected = {"20122013" => @stat_tracker.games[0..3], "20152016" => @stat_tracker.games[4..7]}
    assert_equal expected, @stat_tracker.games_by_season
  end

end
