using System.Globalization;

var appBuilder = WebApplication.CreateBuilder(args);

var app = appBuilder.Build();

static string HandleRollDice(string? player, ILogger<Program> logger)
{
    var result = RollDice();

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

static int RollDice() => Random.Shared.Next(1, 7);

app.MapGet("/rolldice/{player?}", HandleRollDice);

app.Run();
