using System.Globalization;

var app = WebApplication.CreateBuilder(args).Build();

string HandleRollDice(string? player, ILogger<Program> logger)
{
    var result = Random.Shared.Next(1, 7);

    if (string.IsNullOrEmpty(player))
    {
        logger.LogInformation("Anonymous player is rolling the dice: {result}", result);
    }
    else
    {
        logger.LogInformation("{player} is rolling the dice: {result}", player, result);
    }

    return result.ToString(CultureInfo.InvariantCulture);
}

app.MapGet("/rolldice/{player?}", HandleRollDice);

app.Run();
