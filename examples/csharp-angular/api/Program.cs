var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/health", () => Results.Json(new { status = "ok" }));

app.Run();

// Lets the test project start the app through WebApplicationFactory<Program>.
public partial class Program { }
