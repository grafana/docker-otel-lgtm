using OpenTelemetry.Instrumentation.AspNetCore;
using OpenTelemetry.Logs;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using System.Globalization;

var appBuilder = WebApplication.CreateBuilder(args);

// Build a resource configuration action to set service information.
Action<ResourceBuilder> configureResource = r => r.AddService(
    serviceName: appBuilder.Configuration.GetValue("ServiceName", defaultValue: "otel-test")!,
    serviceVersion: typeof(Program).Assembly.GetName().Version?.ToString() ?? "unknown",
    serviceInstanceId: Environment.MachineName);

const string DefaultEndpoint = "http://localhost:4317";

// Configure OpenTelemetry tracing and metrics with auto-start using the
// AddOpenTelemetry() extension method from the OpenTelemetry.Extensions.Hosting package.
appBuilder.Services.AddOpenTelemetry()
    .ConfigureResource(configureResource)
    .WithTracing(builder =>
    {
        builder
            .AddHttpClientInstrumentation()
            .AddAspNetCoreInstrumentation();

        // Use IConfiguration binding for AspNetCore instrumentation options.
        appBuilder.Services.Configure<AspNetCoreTraceInstrumentationOptions>(
            appBuilder.Configuration.GetSection("AspNetCoreInstrumentation"));

        builder.AddOtlpExporter(otlpOptions =>
        {
            // Use IConfiguration directly for OTLP exporter endpoint option.
            otlpOptions.Endpoint = new Uri(
                appBuilder.Configuration.GetValue("Otlp:Endpoint", defaultValue: DefaultEndpoint)!);
        });
    })
    .WithMetrics(builder =>
    {
        builder
            .AddHttpClientInstrumentation()
            .AddAspNetCoreInstrumentation();

        builder.AddOtlpExporter(otlpOptions =>
        {
            // Use IConfiguration directly for OTLP exporter endpoint option.
            otlpOptions.Endpoint = new Uri(
                appBuilder.Configuration.GetValue("Otlp:Endpoint", defaultValue: DefaultEndpoint)!);
        });
    });

// Clear default logging providers used by WebApplication host.
appBuilder.Logging.ClearProviders();

// Configure OpenTelemetry Logging.
appBuilder.Logging.AddOpenTelemetry(options =>
{
    // See appsettings.json "Logging:OpenTelemetry" section for configuration.
    var resourceBuilder = ResourceBuilder.CreateDefault();
    configureResource(resourceBuilder);
    options.SetResourceBuilder(resourceBuilder);

    options.AddOtlpExporter(otlpOptions =>
    {
        // Use IConfiguration directly for OTLP exporter endpoint option.
        otlpOptions.Endpoint = new Uri(
            appBuilder.Configuration.GetValue( "Otlp:Endpoint", defaultValue: DefaultEndpoint)!);
    });
});

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
