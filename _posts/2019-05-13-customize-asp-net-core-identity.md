---
permalink:	/:categories/:year/:month/:day/:title/
layout:     post
title:      Customize ASP.NET Core Identity
date:       2019-05-13 17:00:00
author:     Raimund Rittnauer
description:    Customize ASP.NET Core Identity and Identity Razor Pages to use a custom user model
categories: tech
comments: true
tags:
 - identity
 - asp.net
 - userstore
 - razor pages
---

This Post is a litte example how to customize [ASP.NET Core Identity][1]{:target="_blank"} and the scaffolded [Identity Razor Pages][2]{:target="_blank"} to use a different user model instead of the default *IdentityUser* for authentication.

To use a different user model we have to 

* create our user model
* implement a user store
* register our services
* override scaffolded [Identity Razor Pages][2]{:target="_blank"}

## Create our user model

Lets assume we want to use the following *User* model for authentication.

``` c#
public class User
{
    public Guid Id { get; set; }
    public string Username { get; set; }
    public string PasswordHash { get; set; }
}
```

The default implementation of the [*PasswordHasher*][7]{:target="_blank"} uses the following hashing algorithms

* Version 2: PBKDF2 with HMAC-SHA1, 128-bit salt, 256-bit subkey, 1000 iterations
* Version 3: PBKDF2 with HMAC-SHA256, 128-bit salt, 256-bit subkey, 10000 iterations

If you want to use you own *PasswordHasher*, you just have to implement [*IPasswordHasher*][8]{:target="_blank"} and register it as a service in you startup.

## Implement a user store

Now we have to create a custom *UserStore*. In this example I called it *ToDoUserStore*, implemented the required interfaces and registered it in our *Startup* class.

You can implement additional interfaces to add functionality to your new user store. All optional interfaces are listed in the [documentation][4]{:target="_blank"}.

``` c#
public class ToDoUserStore : IUserPasswordStore<User>, IUserEmailStore<User>
{
    private readonly ToDoDbContext _context;

    public ToDoUserStore(ToDoDbContext context)
    {
        _context = context;
    }

    public void Dispose()
    {
    }

    public async Task<IdentityResult> CreateAsync(User user, CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        if (user == null) throw new ArgumentNullException(nameof(user));
        _context.Add(user);
        var affectedRows = await _context.SaveChangesAsync(cancellationToken);
        return affectedRows > 0
            ? IdentityResult.Success
            : IdentityResult.Failed(new IdentityError() {Description = $"Could not create user {user.Username}."});
    }

    public async Task<IdentityResult> DeleteAsync(User user, CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        if (user == null) throw new ArgumentNullException(nameof(user));
        var userFromDb = await _context.User.FindAsync(user.Id);
        _context.Remove(userFromDb);
        var affectedRows = await _context.SaveChangesAsync(cancellationToken);
        return affectedRows > 0
            ? IdentityResult.Success
            : IdentityResult.Failed(new IdentityError() {Description = $"Could not delete user {user.Username}."});
    }

    public async Task<User> FindByIdAsync(string userId, CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        return await _context.User.SingleOrDefaultAsync(u => u.Id.Equals(Guid.Parse(userId)), cancellationToken);
    }

    public async Task<User> FindByNameAsync(string normalizedUserName,
        CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        return await _context.User.SingleOrDefaultAsync(u => u.Username.Equals(normalizedUserName.ToLower()),
            cancellationToken);
    }

    public Task<string> GetNormalizedUserNameAsync(User user, CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        if (user == null) throw new ArgumentNullException(nameof(user));
        return Task.FromResult(user.Username);
    }

    public Task<string> GetUserIdAsync(User user, CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        if (user == null) throw new ArgumentNullException(nameof(user));
        return Task.FromResult(user.Id.ToString());
    }

    public Task<string> GetUserNameAsync(User user, CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        if (user == null) throw new ArgumentNullException(nameof(user));
        return Task.FromResult(user.Username);
    }

    public Task SetNormalizedUserNameAsync(User user, string normalizedName,
        CancellationToken cancellationToken = default)
    {
        return Task.FromResult<object>(null);
    }

    public Task SetUserNameAsync(User user, string userName, CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        if (user == null) throw new ArgumentNullException(nameof(user));
        user.Username = userName;
        return Task.FromResult<object>(null);
    }

    public async Task<IdentityResult> UpdateAsync(User user, CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        if (user == null) throw new ArgumentNullException(nameof(user));
        _context.Update(user);
        var affectedRows = await _context.SaveChangesAsync(cancellationToken);
        return affectedRows > 0
            ? IdentityResult.Success
            : IdentityResult.Failed(new IdentityError() {Description = $"Could not update user {user.Username}."});
    }

    public Task<string> GetPasswordHashAsync(User user, CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        if (user == null) throw new ArgumentNullException(nameof(user));
        return Task.FromResult(user.PasswordHash);
    }

    public Task<bool> HasPasswordAsync(User user, CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        if (user == null) throw new ArgumentNullException(nameof(user));
        return Task.FromResult(!string.IsNullOrWhiteSpace(user.PasswordHash));
    }

    public Task SetPasswordHashAsync(User user, string passwordHash, CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        if (user == null) throw new ArgumentNullException(nameof(user));
        user.PasswordHash = passwordHash;
        return Task.FromResult<object>(null);
    }

    public async Task<User> FindByEmailAsync(string normalizedEmail, CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        return await _context.User.SingleOrDefaultAsync(u => u.Username.Equals(normalizedEmail),
            cancellationToken);
    }

    public Task<string> GetEmailAsync(User user, CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        if (user == null) throw new ArgumentNullException(nameof(user));
        return Task.FromResult(user.Username);
    }

    public Task<bool> GetEmailConfirmedAsync(User user, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(true);
    }

    public Task<string> GetNormalizedEmailAsync(User user, CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        if (user == null) throw new ArgumentNullException(nameof(user));
        return Task.FromResult(user.Username);
    }

    public Task SetEmailAsync(User user, string email, CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        if (user == null) throw new ArgumentNullException(nameof(user));
        user.Username = email;
        return Task.FromResult<object>(null);
    }

    public Task SetEmailConfirmedAsync(User user, bool confirmed, CancellationToken cancellationToken = default)
    {
        return Task.FromResult<object>(null);
    }

    public Task SetNormalizedEmailAsync(User user, string normalizedEmail,
        CancellationToken cancellationToken = default)
    {
        return Task.FromResult<object>(null);
    }
}
```

## Register our services

After we created our *ToDoUserStore* we have to register it in our startup class. There is already an *AddUserStore* extension method available.

``` c#
services.AddDefaultIdentity<User>()
            .AddDefaultUI(UIFramework.Bootstrap4)
            .AddUserStore<ToDoUserStore>();
```

The full source of *Startup.cs*

``` c#
public class Startup
{
    public Startup(IConfiguration configuration)
    {
        Configuration = configuration;
    }

    public IConfiguration Configuration { get; }

    public void ConfigureServices(IServiceCollection services)
    {
        ConfigureDatabaseServices(services);
        ConfigureDefaultServices(services);
    }

    protected void ConfigureDefaultServices(IServiceCollection services)
    {
        services.Configure<CookiePolicyOptions>(options => { options.CheckConsentNeeded = context => true; });
        // use the User model and register ToDoUserStore
        services.AddDefaultIdentity<User>()
            .AddDefaultUI(UIFramework.Bootstrap4)
            .AddUserStore<ToDoUserStore>();
        services.AddControllersWithViews()
            .AddNewtonsoftJson();
        services.AddRazorPages();
        services.AddScoped<IToDoItemService, ToDoItemService>();
    }

    protected virtual void ConfigureDatabaseServices(IServiceCollection services)
    {
        services.AddDbContext<ToDoDbContext>(options =>
            options.UseSqlite(
                Configuration.GetConnectionString("DefaultConnection"),
                builder => builder.MigrationsAssembly(typeof(Startup).GetTypeInfo().Assembly.GetName().Name)
            ));
    }

    public virtual void Configure(IApplicationBuilder app, IWebHostEnvironment env)
    {
        if (env.IsDevelopment())
        {
            app.UseDeveloperExceptionPage();
            app.UseDatabaseErrorPage();
        }
        else
        {
            app.UseExceptionHandler("/Home/Error");
            app.UseHsts();
        }

        app.UseHttpsRedirection();
        app.UseStaticFiles();

        app.UseCookiePolicy();

        app.UseRouting();

        app.UseAuthentication();
        app.UseAuthorization();

        app.UseEndpoints(endpoints =>
        {
            endpoints.MapDefaultControllerRoute();
            endpoints.MapRazorPages();
        });
    }
}
```

## override scaffolded Identity Razor Pages

After that we can override the Identity Razor Pages for managing just the username and the password. In Visual Studio 2019 you can use the [*New Scaffolded Item...*][5]{:target="_blank"} option to generate the code for the Razor Pages. For the source code see their [AspNetCore GitHub repository][6]{:target="_blank"}.

*Right click on your project -> Add -> New Scaffolded Item...*

In this example we customize the page *Account/Manage/Index*. Now you just have to modify the generated code to use your custom user model and remove all additional functionality you do not need anymore.

*/Account/Manage/_ManageNav.cshtml*

``` c#
<ul class="nav nav-pills flex-column">
    <li class="nav-item">
        <a class="nav-link @ManageNavPages.IndexNavClass(ViewContext)" id="profile" asp-page="./Index">Profile</a>
    </li>
    <li class="nav-item">
        <a class="nav-link @ManageNavPages.ChangePasswordNavClass(ViewContext)" id="change-password" asp-page="./ChangePassword">Password</a>
    </li>
</ul>
```

*/Account/Manage/Index.cshml*

``` c#
@page
@model IndexModel
@{
    ViewData["Title"] = "Profile";
    ViewData["ActivePage"] = ManageNavPages.Index;
}

<h4>@ViewData["Title"]</h4>
<partial name="_StatusMessage" for="StatusMessage"/>
<div class="row">
    <div class="col-md-6">
        <form id="profile-form" method="post">
            <div asp-validation-description="All" class="text-danger"></div>
            <div class="form-group">
                <label asp-for="Input.Username"></label>
                <input asp-for="Input.Username" class="form-control"/>
                <span asp-validation-for="Input.Username" class="text-danger"></span>
            </div>
            <button id="update-profile-button" type="submit" class="btn btn-primary">Save</button>
        </form>
    </div>
</div>

@section Scripts {
    <partial name="_ValidationScriptsPartial"/>
}
```

*/Account/Manage/Index.cshtml.cs*

``` c#
public class IndexModel : PageModel
{
    private readonly UserManager<User> _userManager;
    private readonly SignInManager<User> _signInManager;
    private readonly IEmailSender _emailSender;

    public IndexModel(
        UserManager<User> userManager,
        SignInManager<User> signInManager,
        IEmailSender emailSender)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _emailSender = emailSender;
    }

    public string Username { get; set; }

    [TempData] public string StatusMessage { get; set; }

    [BindProperty] public InputModel Input { get; set; }

    public class InputModel
    {
        [Required] [EmailAddress] public string Username { get; set; }
    }

    public async Task<IActionResult> OnGetAsync()
    {
        var user = await _userManager.GetUserAsync(User);
        if (user == null)
            return NotFound($"Unable to load user with ID '{_userManager.GetUserId(User)}'.");

        var userName = await _userManager.GetUserNameAsync(user);

        Username = userName;

        Input = new InputModel
        {
            Username = userName
        };

        return Page();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        if (!ModelState.IsValid) return Page();

        var user = await _userManager.GetUserAsync(User);
        if (user == null) return NotFound($"Unable to load user with ID '{_userManager.GetUserId(User)}'.");

        if (Input.Username != user.Username)
        {
            var setUsernameResult = await _userManager.SetUserNameAsync(user, Input.Username);
            if (!setUsernameResult.Succeeded)
            {
                var userId = await _userManager.GetUserIdAsync(user);
                throw new InvalidOperationException(
                    $"Unexpected error occurred setting email for user with ID '{userId}'.");
            }
        }

        await _signInManager.RefreshSignInAsync(user);
        StatusMessage = "Your profile has been updated";
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostSendVerificationEmailAsync()
    {
        if (!ModelState.IsValid) return Page();

        var user = await _userManager.GetUserAsync(User);
        if (user == null) return NotFound($"Unable to load user with ID '{_userManager.GetUserId(User)}'.");

        var userId = await _userManager.GetUserIdAsync(user);
        var email = await _userManager.GetEmailAsync(user);
        var code = await _userManager.GenerateEmailConfirmationTokenAsync(user);
        var callbackUrl = Url.Page(
            "/Account/ConfirmEmail",
            pageHandler: null,
            values: new {userId = userId, code = code},
            protocol: Request.Scheme);
        await _emailSender.SendEmailAsync(
            email,
            "Confirm your email",
            $"Please confirm your account by <a href='{HtmlEncoder.Default.Encode(callbackUrl)}'>clicking here</a>.");

        StatusMessage = "Verification email sent. Please check your email.";
        return RedirectToPage();
    }
}
```

*/Account/Manage/ManageNavPages.cs*

``` c#
 public static class ManageNavPages
{
    public static string Index => "Index";

    public static string ChangePassword => "ChangePassword";

    public static string IndexNavClass(ViewContext viewContext) => PageNavClass(viewContext, Index);

    public static string ChangePasswordNavClass(ViewContext viewContext) =>
        PageNavClass(viewContext, ChangePassword);

    private static string PageNavClass(ViewContext viewContext, string page)
    {
        var activePage = viewContext.ViewData["ActivePage"] as string
                            ?? System.IO.Path.GetFileNameWithoutExtension(viewContext.ActionDescriptor.DisplayName);
        return string.Equals(activePage, page, StringComparison.OrdinalIgnoreCase) ? "active" : null;
    }
}
```

Now you should be able to authenticate a user, register new users and manage the username and password.

This project is available on [github][3]{:target="_blank"}.

Useful links

* <https://docs.microsoft.com/en-us/aspnet/core/security/app-secrets?view=aspnetcore-2.2&tabs=windows#secret-manager>
* <https://docs.microsoft.com/en-us/aspnet/core/security/authentication/customize-identity-model?view=aspnetcore-2.2>
* <https://docs.microsoft.com/en-us/aspnet/core/security/authentication/identity-custom-storage-providers?view=aspnetcore-2.2>
* <https://github.com/aspnet/AspNetCore.Docs/blob/master/aspnetcore/security/authentication/identity-custom-storage-providers/sample/CustomIdentityProviderSample/CustomProvider/CustomUserStore.cs>
* <https://csharp.christiannagel.com/2018/07/18/identitypages/>

[1]: https://docs.microsoft.com/en-us/aspnet/core/security/authentication/identity?view=aspnetcore-2.2&tabs=visual-studio
[2]: https://docs.microsoft.com/en-us/aspnet/core/razor-pages/?view=aspnetcore-2.2&tabs=visual-studio
[3]: https://github.com/raaaimund/ToDo/tree/aspnetcore-unit-testing
[4]: https://docs.microsoft.com/en-us/aspnet/core/security/authentication/identity-custom-storage-providers?view=aspnetcore-2.2#customize-the-user-store
[5]: https://docs.microsoft.com/en-us/aspnet/core/security/authentication/scaffold-identity?view=aspnetcore-2.2&tabs=visual-studio#scaffold-identity-into-an-mvc-project-without-existing-authorization
[6]: https://github.com/aspnet/AspNetCore/tree/master/src/Identity/UI/src
[7]: https://github.com/aspnet/AspNetCore/blob/master/src/Identity/Extensions.Core/src/PasswordHasher.cs
[8]: https://github.com/aspnet/AspNetCore/blob/master/src/Identity/Extensions.Core/src/IPasswordHasher.cs
