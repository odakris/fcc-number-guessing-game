#!/bin/bash

# Title
echo -e "\n~~~~~~~~~~  Number Guessing Game  ~~~~~~~~~~\n"

# Database query variable
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

NUMBER_GUESSING_GAME() {
  # Generate a number between 1 and 1000
  NUM_GENERATOR

  # Prompt user for username
  echo "Enter your username:"
  read USERNAME

  # Welcome user
  WELCOME_USER $USERNAME

  # Prompt user for first guess
  echo "Guess the secret number between 1 and 1000:"
  read GUESS

  # Guess number loop
  GUESS_NUMBER $GUESS $RANDOM_NUM

  # Insert user data into database
  INSERT_DATA $USERNAME $TRIES $GET_USER_INFO

  # Winning line
  echo "You guessed it in $TRIES tries. The secret number was $RANDOM_NUM. Nice job!"
}

NUM_GENERATOR() {
  # Define max number
  MAX_NUM=1000
  # Generate random number
  RANDOM_NUM=$(($RANDOM % $MAX_NUM + 1))
}

WELCOME_USER() {
  USERNAME=$1

  # Search user in database
  GET_USER_INFO=$($PSQL "SELECT username,game_played,best_game FROM users WHERE username='$USERNAME'")

  # Check if user already in database
  if [[ $GET_USER_INFO ]]
  then
    # If user in database
    echo "$GET_USER_INFO" | while IFS='|' read USERNAME GAME_PLAYED BEST_GAME
    do
      echo "Welcome back, $USERNAME! You have played $GAME_PLAYED games, and your best game took $BEST_GAME guesses."
    done
  else
    # If user not in database
    echo "Welcome, $USERNAME! It looks like this is your first time here."
  fi
}

GUESS_NUMBER() {
  GUESS=$1
  RANDOM_NUM=$2

  # Tries variable initialization
  TRIES=1

  # Runs until user find RANDOM_NUM
  until [[ $GUESS == $RANDOM_NUM ]]
  do
    if [[ $GUESS =~ ^[0-9]+$ ]]
    then
      # If GUESS is an integer
      if [[ $GUESS -lt $RANDOM_NUM ]]
      then
        # If GUESS is lower than RANDOM_NUM
        echo "It's higher than that, guess again:"
        read GUESS 
      elif [[ $GUESS -gt $RANDOM_NUM ]]
      then
        # If GUESS is higher than RANDOM_NUM
        echo "It's lower than that, guess again:"
        read GUESS 
      fi
      # Increment TRIES variable
      (( TRIES++ ))
    else
      # If GUESS is not an integer
      echo "That is not an integer, guess again:"
      read GUESS
    fi
  done
}

INSERT_DATA() {
  USERNAME=$1
  TRIES=$2
  GET_USER_INFO=$3
  
  # Check if user already in database
  if [[ $GET_USER_INFO ]]
  then
    # If not new player, get info from user
    GAME_PLAYED=$($PSQL "SELECT game_played FROM users WHERE username='$USERNAME'")
    BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE username='$USERNAME'")

    if [[ $TRIES -lt $BEST_GAME ]]
    then
      # If user tries is lower than his best game recorded
      UPDATE=$($PSQL "UPDATE users SET game_played=$GAME_PLAYED+1,best_game=$TRIES WHERE username='$USERNAME'")
    else
      # If user tries is higher than his best game recorded
      UPDATE=$($PSQL "UPDATE users SET game_played=$GAME_PLAYED+1 WHERE username='$USERNAME'")
    fi
  else
    # If new player
    INSERT=$($PSQL "INSERT INTO users(username,game_played,best_game) VALUES('$USERNAME',1,$TRIES)")
  fi
}

NUMBER_GUESSING_GAME