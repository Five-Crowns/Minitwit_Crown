using System.Security.Claims;
using Chirp.Infrastructure.Data;
using Chirp.Infrastructure.Repositories;
using Chirp.Infrastructure.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;



namespace Chirp.Web
{
    public class Program
    {
        public static void Main(string[] args)
        {
            // Create the WebApplicationBuilder
            var builder = WebApplication.CreateBuilder(args);
            
            //CORS 
            builder.Services.AddCors(options =>
            {
                options.AddDefaultPolicy(
                    policy  =>
                    {
                        policy.WithOrigins("https://bdsagroup07chirprazor.azurewebsites.net/",
                            "http://localhost:");
                    });
            });
            
            // Add services to the container
            builder.Services.AddRazorPages();
            
            // Once you are sure everything works, you might want to increase this value to up to 1 or 2 years
            builder.Services.AddHsts(options => options.MaxAge = TimeSpan.FromDays(700));
            
            // Determine if we are running tests
            var isTesting = args.Contains("test");
            
            // Load the appropriate connection string
            string? connectionString = isTesting
                ? builder.Configuration.GetConnectionString("TestConnection")
                : builder.Configuration.GetConnectionString("DefaultConnection");

            // Add the DbContext first
            builder.Services.AddDbContext<CheepDBContext>(options => options.UseSqlite(connectionString));
            
            // Then add Identity services
            builder.Services.AddDefaultIdentity<ApplicationUser>(options =>
                    options.SignIn.RequireConfirmedAccount = true)
                .AddSignInManager<SignInManager<ApplicationUser>>()
                .AddEntityFrameworkStores<CheepDBContext>();
            
            
            // Add the authorization policy
            builder.Services.AddDistributedMemoryCache();

            builder.Services.AddSession(options =>
            {
                options.IdleTimeout = TimeSpan.FromSeconds(10);
                options.Cookie.HttpOnly = true;
                options.Cookie.IsEssential = true;
            });
            
            // Register your repositories and services
            builder.Services.AddScoped<CheepRepository>();
            builder.Services.AddScoped<AuthorRepository>();
            builder.Services.AddScoped<CheepService>();
            builder.Services.AddScoped<AuthorService>();

            // Build the application
            var app = builder.Build();

            // Seed the database after the application is built
            using (var scope = app.Services.CreateScope())
            {
                var services = scope.ServiceProvider;
                var context = services.GetRequiredService<CheepDBContext>();
                
                context.Database.Migrate();
                
                DbInitializer.SeedDatabase(context);
            }
            

            // Configure the HTTP request pipeline
            if (!app.Environment.IsDevelopment())
            {
                app.UseExceptionHandler("/Error");
                app.UseHsts();
            }
            
            app.Use(async (context, next) =>
            {
                // The Content-Security-Policy header helps to protect the webapp from XSS attacks.
                // Added connect-src to allow WebSocket connections
                context.Response.Headers.Append("Content-Security-Policy", 
                    "default-src 'self'; " +                            // Allow resources from the same origin
                    "script-src 'self' https://bdsagroup07chirprazor.azurewebsites.net/; " +  // Allow scripts from self and Azure
                    "style-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com; " + // Allow styles from Font Awesome CDN
                    "style-src 'self' 'unsafe-inline'; " +               // Allow inline styles and styles from self
                    "img-src 'self' data:; " +  // Allow images from self and Base64-encoded images
                    "script-src-elem 'self' 'unsafe-inline'; " +         // Allow inline scripts in elements
                    "connect-src 'self' ws://localhost:53540/ wss://localhost:53539/ https://bdsagroup07chirprazor.azurewebsites.net/; " + // Allow WebSocket connections from localhost and Azure
                    "font-src 'self' https://cdnjs.cloudflare.com; " + // Allow fonts from Font Awesome CDN
                    "font-src 'self'; " +                                // Allow fonts from self
                    "frame-src 'self'; " +                               // Allow frames from self
                    "object-src 'none'; " +                              // Disallow object elements
                    "script-src 'self' 'unsafe-inline' https://bdsagroup07chirprazor.azurewebsites.net/;" + // Allow scripts from self and Azure
                    "worker-src 'self';");                               // Allow workers from self
                await next();
            });
            
            //Use CORS
            app.UseCors();
            
            app.UseHttpsRedirection();
            app.UseStaticFiles();
            app.UseRouting();
            app.UseSession();
            app.UseAuthentication();
            app.UseAuthorization();

            // Map Razor Pages
            app.MapRazorPages();
            
            // Original endpoints
            app.MapGet("/{userName}/follows", async (string userName, AuthorService authorService) =>
            {
                var followedAuthors = await authorService.GetFollowedAuthors(userName);
                return Results.Ok(followedAuthors);
            });
                        
            app.MapGet("/cheeps", async (CheepService cheepService) =>
            {
                var cheeps = await cheepService.RetrieveAllCheeps();
                return Results.Ok(cheeps);
            });
            
            // Endpoints added for tests
            app.MapGet("/logout", context =>
            {
                context.Response.Redirect("/Identity/Account/Logout");
                return Task.CompletedTask;
            });
            
            app.MapPost("/register", async (HttpContext context, UserManager<ApplicationUser> userManager, SignInManager<ApplicationUser> signInManager) =>
            {
                var form = await context.Request.ReadFormAsync();
                var username = form["username"].ToString();
                var password = form["password"].ToString();
                var email = form["email"].ToString();

                var user = new ApplicationUser { UserName = username, Email = email };
                var result = await userManager.CreateAsync(user, password);

                if (result.Succeeded)
                {
                    await signInManager.SignInAsync(user, isPersistent: false);
                    return Results.Redirect("/"); // Redirect after successful registration
                }
                else
                {
                    // Handle registration errors
                    foreach (var error in result.Errors)
                    {
                        Console.WriteLine(error.Description);
                    }
                    return Results.BadRequest("Registration failed.");
                }
            });

            app.MapPost("/login", async (HttpContext context, SignInManager<ApplicationUser> signInManager) =>
            {
                var form = await context.Request.ReadFormAsync();
                var username = form["username"].ToString();
                var password = form["password"].ToString();

                var result = await signInManager.PasswordSignInAsync(username, password, isPersistent: false, lockoutOnFailure: false);

                if (result.Succeeded)
                {
                    return Results.Redirect("/"); // Redirect after successful login
                }
                else
                {
                    return Results.BadRequest("Login failed.");
                }
            });
            
            app.MapGet("/{userName}/follow", async (HttpContext context, string userName, AuthorService authorService) =>
            {
                if (context.User.Identity != null && context.User.Identity.IsAuthenticated)
                {
                    var currentUser = context.User.Identity.Name;
                    if (currentUser != null)
                    {
                        await authorService.FollowAuthor(currentUser, userName);
                        return Results.Redirect($"/Public");
                    }
                }
                return Results.Unauthorized();
            });

            app.MapGet("/{userName}/unfollow", async (HttpContext context, string userName, AuthorService authorService) =>
            {
                if (context.User.Identity != null && context.User.Identity.IsAuthenticated)
                {
                    var currentUser = context.User.Identity.Name;
                    if (currentUser != null)
                    {
                        await authorService.UnfollowAuthor(currentUser, userName);
                        return Results.Redirect($"/Public");
                    }
                    
                }
                return Results.Unauthorized();
            });
            
            app.MapPost("/add_message", async (HttpContext context, CheepService cheepService) =>
            {
                var form = await context.Request.ReadFormAsync();
                var text = form["text"].ToString();

                if (string.IsNullOrEmpty(text))
                {
                    return Results.BadRequest("Message text cannot be empty");
                }

                var authorName = context.User.Identity?.Name;
                if (authorName == null)
                {
                    return Results.Unauthorized();
                }

                await cheepService.CreateCheepDTO(authorName, text);
                return Results.Ok("Your message was recorded");
            });
            
            // Run the application
            app.Run();
        }
    }
}