"""Simple Flask app that rolls a dice."""

import logging
from random import randint

from flask import Flask, request

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@app.route("/rolldice")
def roll_dice():
    """Rolls a dice and returns the result."""
    player = request.args.get("player", default=None, type=str)
    result = str(roll())
    if player:
        logger.warning("%s is rolling the dice: %s", player, result)
    else:
        logger.warning("Anonymous player is rolling the dice: %s", result)
    return result


def roll():
    """Rolls a dice and returns the result."""
    return randint(1, 6)
