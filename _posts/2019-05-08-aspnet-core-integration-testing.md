---
layout:     post
title:      Integration testing in ASP.NET Core with EF Sqlite and InMemory Provider and XUnit
date:       2019-05-08 01:00:00
author:     Raimund Rittnauer
summary:    A simple example how to do integration testing in ASP.NET Core with Entity Framework Core Sqlite and InMemory Provider
categories: tech
comments: true
tags:
 - unit testing
 - asp.net
 - sqlite
 - inmemory
 - anglesharp
 - xunit
---

Just a litte example how to do simple integration testing with the Entity Framework Core Sqlite and InMemory Provider in ASP.NET Core with XUnit and [AngleSharp][2]{:target="_blank"}.

Lets assume we have the following setup.

A Controller *ToDoController*

``` c#
public class ToDoController : Controller
{
    private readonly IToDoItemService _toDoItemService;

    public ToDoController(IToDoItemService toDoItemService)
    {
        this._toDoItemService = toDoItemService ?? throw new ArgumentNullException(nameof(toDoItemService));
    }

    [HttpGet]
    public async Task<IActionResult> Index()
    {
        var items = await _toDoItemService.GetItemsAsync();
        return View(items);
    }

    [HttpGet]
    public IActionResult Create()
    {
        return View();
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(CreateViewModel model)
    {
        if (!ModelState.IsValid) return View(model);
        await _toDoItemService.AddItemAsync(new ToDoItem() {Name = model.Name});
        return RedirectToAction(nameof(Index));
    }

    [HttpGet]
    public async Task<IActionResult> Update(Guid id)
    {
        var item = await _toDoItemService.GetAsync(id);

        if (item == null)
            return NotFound();

        var model = new UpdateViewModel() {Id = item.Id, Name = item.Name};
        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Update(UpdateViewModel model)
    {
        if (!ModelState.IsValid) return View(model);
        await _toDoItemService.UpdateItemAsync(new ToDoItem() {Id = model.Id, Name = model.Name});
        return RedirectToAction(nameof(Index));
    }

    [HttpGet]
    public async Task<IActionResult> Delete(Guid id)
    {
        var item = await _toDoItemService.GetAsync(id);

        if (item == null)
            return NotFound();

        var model = new DeleteViewModel() {Id = item.Id, Name = item.Name};
        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(DeleteViewModel model)
    {
        await _toDoItemService.DeleteItemAsync(model.Id);
        return RedirectToAction(nameof(Index));
    }
}
```

for our model *ToDoItem*

``` c#
public class ToDoItem
{
    public Guid Id { get; set; }
    public string Name { get; set; }
}
```

Our *Startup*.

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
        services.AddIdentity<User>()
            .AddDefaultUI(UIFramework.Bootstrap4)
            .AddDefaultTokenProviders()
            .AddUserStore<ToDoUserStore>();
        services.AddControllersWithViews()
            .AddNewtonsoftJson();
        services.AddRazorPages();
        services.AddScoped<IToDoItemService, ToDoItemService>();
    }

    // We have to override this message in our TestStartup, because we want to inject our custom database services
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

Now in our test project we have to inherit from *Startup* to use a custom *TestStartup* for injectiong our custom database services and seed some test data for our tests.

``` c#
public class TestStartup : Startup
{
    public TestStartup(IConfiguration configuration) : base(configuration)
    {
    }

    protected override void ConfigureDatabaseServices(IServiceCollection services)
    {
        // Database providers are injected in WebApplicationFactoryWithPROVIDER.cs classes
        services.AddTransient<TestDataSeeder>();
    }

    public override void Configure(IApplicationBuilder app, IWebHostEnvironment env)
    {
        base.Configure(app, env);
        using var serviceScope = app.ApplicationServices.GetRequiredService<IServiceScopeFactory>().CreateScope();
        var seeder = serviceScope.ServiceProvider.GetService<TestDataSeeder>();
        seeder.SeedToDoItems();
    }
}
```

``` c#
public class TestDataSeeder
{
    public const string FirstItemId = "312658D1-8146-42E3-B57B-360427182811";
    public const string SecondItemId = "64C7E3F5-74F9-4540-9B12-BC7AFBCC7CE6";

    public static readonly ToDoItem FirstItem = new ToDoItem() {Id = Guid.Parse(FirstItemId), Name = "Item 1"};
    public static readonly ToDoItem SecondItem = new ToDoItem() {Id = Guid.Parse(SecondItemId), Name = "Item 2"};

    private readonly ToDoDbContext _context;

    public TestDataSeeder(ToDoDbContext context)
    {
        _context = context;

        _context.Database.EnsureDeleted();
        _context.Database.EnsureCreated();
    }

    public void SeedToDoItems()
    {
        _context.ToDoItem.Add(FirstItem);
        _context.ToDoItem.Add(SecondItem);
        _context.SaveChanges();
    }
}
```

Now we use the [WebApplicationFactory][1]{:target="_blank"} to bootstrap our test server and client.

``` c#
public abstract class BaseWebApplicationFactory<TStartup> : WebApplicationFactory<TStartup>
    where TStartup : class
{
    protected override IWebHostBuilder CreateWebHostBuilder() =>
        WebHost.CreateDefaultBuilder().UseStartup<TStartup>();
}
```

We can use this as a base class four our custom *WebApplicationFactory* with the different Entity Framework Providers.

``` c#
public class WebApplicationFactoryWithInMemory : BaseWebApplicationFactory<TestStartup>
{
    private readonly InMemoryDatabaseRoot _databaseRoot = new InMemoryDatabaseRoot();
    private readonly string _connectionString = Guid.NewGuid().ToString();

    protected override void ConfigureWebHost(IWebHostBuilder builder) =>
        builder.ConfigureServices(services =>
        {
            services
                .AddEntityFrameworkInMemoryDatabase()
                .AddDbContext<ToDoDbContext>(options =>
                {
                    options.UseInMemoryDatabase(_connectionString, _databaseRoot);
                    options.UseInternalServiceProvider(services.BuildServiceProvider());
                });
        });
}
```

``` c#
public class WebApplicationFactoryWithInMemorySqlite : BaseWebApplicationFactory<TestStartup>
{
    private readonly string _connectionString = "DataSource=:memory:";
    private readonly SqliteConnection _connection;

    public WebApplicationFactoryWithInMemorySqlite()
    {
        _connection = new SqliteConnection(_connectionString);
        _connection.Open();
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder) =>
        builder.ConfigureServices(services =>
        {
            services
                .AddEntityFrameworkSqlite()
                .AddDbContext<ToDoDbContext>(options =>
                {
                    options.UseSqlite(_connection);
                    options.UseInternalServiceProvider(services.BuildServiceProvider());
                });
        });

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        _connection.Close();
    }
}
```

``` c#
public class WebApplicationFactoryWithSqlite : BaseWebApplicationFactory<TestStartup>
{
    private readonly string _connectionString = $"DataSource={Guid.NewGuid()}.db";

    protected override void ConfigureWebHost(IWebHostBuilder builder) =>
        builder.ConfigureServices(services =>
        {
            services
                .AddEntityFrameworkSqlite()
                .AddDbContext<ToDoDbContext>(options =>
                {
                    options.UseSqlite(_connectionString);
                    options.UseInternalServiceProvider(services.BuildServiceProvider());
                });
        });
}
```

With this we can do a basic endpoint test for our GET endpoints.

``` c#
public abstract class BaseEndpointTests
{
    protected BaseWebApplicationFactory<TestStartup> Factory { get; }

    protected BaseEndpointTests(BaseWebApplicationFactory<TestStartup> factory) =>
        Factory = factory;

    public static readonly IEnumerable<object[]> Endpoints = new List<object[]>()
    {
        new object[] {"/ToDo"},
        new object[] {"/ToDo/Create"},
        new object[] {$"/ToDo/Update/{TestDataSeeder.FirstItemId}"},
        new object[] {$"/ToDo/Delete/{TestDataSeeder.FirstItemId}"},
    };

    [Theory]
    [MemberData(nameof(Endpoints))]
    public async Task GetEndpointsReturnSuccessAndCorrectContentType(string url)
    {
        const string expectedContentType = "text/html; charset=utf-8";
        var client = Factory.CreateClient();

        var response = await client.GetAsync(url);

        response.EnsureSuccessStatusCode();
        Assert.Equal(expectedContentType,
            response.Content.Headers.ContentType.ToString());
    }
}
```

``` c#
public class EndpointTestsWithInMemory : BaseEndpointTests, IClassFixture<WebApplicationFactoryWithInMemory>
{
    public EndpointTestsWithInMemory(WebApplicationFactoryWithInMemory factory) : base(factory)
    {
    }
}
```

``` c#
public class EndpointTestsWithInMemorySqlite : BaseEndpointTests, IClassFixture<WebApplicationFactoryWithInMemorySqlite>
{
    public EndpointTestsWithInMemorySqlite(WebApplicationFactoryWithInMemorySqlite factory) : base(factory)
    {
    }
}
```

``` c#
public class EndpointTestsWithSqlite : BaseEndpointTests, IClassFixture<WebApplicationFactoryWithSqlite>
{
    public EndpointTestsWithSqlite(WebApplicationFactoryWithSqlite factory) : base(factory)
    {
    }
}
```

Now we can use [AngleSharp][2]{:target="_blank"} to test if our view renders the two items in our test database.

``` c#
@using ToDo.Dto
@model IEnumerable<ToDoItem>
@{
    ViewData["Title"] = "My ToDos";
}

<h1 class="display-4">My ToDos</h1>
<div class="mt-5"></div>
<ul>
    @foreach (var item in Model)
    {
    <li class="todo-item">
        <a asp-action="@nameof(ToDo.Web.Controllers.ToDoController.Update)" asp-route-id="@item.Id">@item.Name</a>
        |
        <a asp-action="@nameof(ToDo.Web.Controllers.ToDoController.Delete)" asp-route-id="@item.Id">Delete</a>
    </li>
    }
</ul>
<div class="mt-5"></div>
<a asp-action="Create" class="btn btn-primary">New item</a>
````

``` c#
/// <summary>
/// Original: https://github.com/aspnet/AspNetCore.Docs/blob/master/aspnetcore/test/integration-tests/samples/2.x/IntegrationTestsSample/tests/RazorPagesProject.Tests/Helpers/HtmlHelpers.cs
/// </summary>
public static class HtmlHelpers
{
    public static async Task<IHtmlDocument> GetDocumentAsync(HttpResponseMessage response)
    {
        var content = await response.Content.ReadAsStringAsync();
        var document = await BrowsingContext.New()
            .OpenAsync(ResponseFactory, CancellationToken.None);
        return (IHtmlDocument)document;

        void ResponseFactory(VirtualResponse htmlResponse)
        {
            htmlResponse
                .Address(response.RequestMessage.RequestUri)
                .Status(response.StatusCode);

            MapHeaders(response.Headers);
            MapHeaders(response.Content.Headers);

            htmlResponse.Content(content);

            void MapHeaders(HttpHeaders headers)
            {
                foreach (var header in headers)
                {
                    foreach (var value in header.Value)
                    {
                        htmlResponse.Header(header.Key, value);
                    }
                }
            }
        }
    }
}
```

``` c#
public abstract class BaseIndexTests
{
    protected BaseWebApplicationFactory<TestStartup> Factory { get; }

    protected BaseIndexTests(BaseWebApplicationFactory<TestStartup> factory) =>
        Factory = factory;

    [Fact]
    public async Task DisplaysAllToDoItems()
    {
        var client = Factory.CreateClient();
        var indexView = await client.GetAsync("/ToDo");

        Assert.Equal(HttpStatusCode.OK, indexView.StatusCode);
        var indexViewHtml = await HtmlHelpers.GetDocumentAsync(indexView);
        var todoItems = indexViewHtml.QuerySelectorAll(".todo-item");

        Assert.Equal(2, todoItems.Length);
    }
}
```

``` c#
public class IndexTestsWithInMemory : BaseIndexTests, IClassFixture<WebApplicationFactoryWithInMemory>
{
    public IndexTestsWithInMemory(WebApplicationFactoryWithInMemory factory) : base(factory)
    {
    }
}
```

``` c#
public class IndexTestsWithInMemorySqlite : BaseIndexTests, IClassFixture<WebApplicationFactoryWithInMemorySqlite>
{
    public IndexTestsWithInMemorySqlite(WebApplicationFactoryWithInMemorySqlite factory) : base(factory)
    {
    }
}
```

``` c#
public class IndexTestsWithSqlite : BaseIndexTests, IClassFixture<WebApplicationFactoryWithSqlite>
{
    public IndexTestsWithSqlite(WebApplicationFactoryWithSqlite factory) : base(factory)
    {
    }
}
```

This project is available on [github][3]{:target="_blank"}.

For more details about integration testing take a look at the [ASP.NET Core documentation][4]{:target="_blank"}.

Useful links

* <https://stackoverflow.com/questions/46784989/unit-test-with-static-value>
* <https://docs.microsoft.com/en-us/dotnet/framework/app-domains/application-domains>
* <https://docs.microsoft.com/en-us/aspnet/core/test/integration-tests?view=aspnetcore-3.0>
* <https://docs.microsoft.com/en-us/dotnet/api/microsoft.aspnetcore.mvc.testing.webapplicationfactory-1?view=aspnetcore-2.2&viewFallbackFrom=aspnetcore-3.0>
* <https://github.com/aspnet/AspNetCore.Docs/tree/master/aspnetcore/test/integration-tests/samples/2.x/IntegrationTestsSample>
* <https://github.com/aspnet/EntityFrameworkCore/issues/9613>
* <https://www.dotnetcurry.com/aspnet-core/1420/integration-testing-aspnet-core>
* <https://xunit.net/docs/shared-context>
* <http://hamidmosalla.com/2017/02/25/xunit-theory-working-with-inlinedata-memberdata-classdata/>
* <https://www.hanselman.com/blog/EasierFunctionalAndIntegrationTestingOfASPNETCoreApplications.aspx>

[1]: https://docs.microsoft.com/en-us/aspnet/core/test/integration-tests?view=aspnetcore-2.2#basic-tests-with-the-default-webapplicationfactory
[2]: https://github.com/AngleSharp/AngleSharp
[3]: https://github.com/raaaimund/ToDo
[4]: https://docs.microsoft.com/en-us/aspnet/core/test/integration-tests?view=aspnetcore-2.2