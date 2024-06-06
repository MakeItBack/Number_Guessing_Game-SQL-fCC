#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo -e "Enter your username:"
read ENTERED_USERNAME

# check database for username
USER_DATA=$($PSQL "SELECT username, games_played, best_game FROM users WHERE username='$ENTERED_USERNAME'")
# echo $USER_DATA

if [[ -z $USER_DATA ]]
# New user
then
  echo -e "Welcome, $ENTERED_USERNAME! It looks like this is your first time here."
  GAMES_PLAYED=0; BEST_GAME=0
  ADD_USER_RESULT=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$ENTERED_USERNAME',$GAMES_PLAYED, $BEST_GAME)")
  USERNAME=$ENTERED_USERNAME
# Existing user
else
  # save returned user data to variables
  IFS='|' read -r USERNAME GAMES_PLAYED BEST_GAME <<< "$USER_DATA"
  # echo "variables $USERNAME $GAMES_PLAYED $BEST_GAME"
  # print welcome back message to user
  echo -e "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Initialise game variables
# Define the minimum and maximum values of the range
MIN_NUMBER=1; MAX_NUMBER=1000
NUMBER_RANGE=$(( MAX_NUMBER - MIN_NUMBER + 1))
# Generate a random number within the range
SECRET_NUMBER=$(( RANDOM % NUMBER_RANGE + MIN_NUMBER ))
# - zero the number of guesses
NUMBER_OF_GUESSES=0

# Define the game logic
PLAY_GAME(){
  GUESS=$1
  # Increment the NUMBER_OF_GUESSES variable
  (( NUMBER_OF_GUESSES += 1 ))

  # check if guess is an integer (a valid guess)
  PATTERN='^[1-9][0-9]*$'

  if [[ ! "$GUESS" =~ $PATTERN   ]]; then
    # Not a valid guess
    echo -e "That is not an integer, guess again:"
    read NEW_GUESS
    PLAY_GAME $NEW_GUESS

  else
    # Valid guess - check the guess against the secret number

    # Guess is lower than secret number
    if [[ $GUESS -lt $SECRET_NUMBER  ]]; then
        echo -e "It's higher than that, guess again:"
        read NEW_GUESS
        PLAY_GAME $NEW_GUESS

    # Guess is higher than secret number
    elif [[ $GUESS -gt $SECRET_NUMBER  ]]; then
        echo -e "It's lower than that, guess again:"
        read NEW_GUESS
        PLAY_GAME $NEW_GUESS

    # Winning guess
    else
        # Overwrite best game score (if latest is lower than current or if current is zero) and update in db
        if [[ $BEST_GAME -eq 0 ]]; then
          BEST_GAME=$NUMBER_OF_GUESSES
          UPDATE_BESTGAME_RESULT=$($PSQL "UPDATE users SET best_game=$BEST_GAME WHERE username='$USERNAME' ")
        elif [[ $NUMBER_OF_GUESSES -lt $BEST_GAME ]]; then
          BEST_GAME=$NUMBER_OF_GUESSES
          UPDATE_BESTGAME_RESULT=$($PSQL "UPDATE users SET best_game=$BEST_GAME WHERE username='$USERNAME' ")
        fi

        echo -e "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    fi
  fi
}

# Start the game
echo -e "Guess the secret number between 1 and 1000:"
read GUESS
(( GAMES_PLAYED +=1 ))
UPDATE_GAMESCOUNT_RESULT=$($PSQL "UPDATE users SET games_played=$GAMES_PLAYED WHERE username='$USERNAME' ")
PLAY_GAME $GUESS