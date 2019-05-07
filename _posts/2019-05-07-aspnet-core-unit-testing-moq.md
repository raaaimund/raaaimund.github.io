---
layout:     post
title:      Unit testing in ASP.NET Core with Moq and XUnit
date:       2019-05-07 23:00:00
author:     Raimund Rittnauer
summary:    A simple example how to do unit testing in ASP.NET Core with Moq and XUnit
categories: tech
comments: true
tags:
 - unit testing
 - asp.net
 - moq
 - xunit
---

Just a litte example how to use [Moq][1]{:target="_blank"} together with simple unit testing in ASP.NET Core and XUnit.

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

To manipulate the data the controller uses the *IToDoItemService*.

``` c#
public interface IToDoItemService
{
    Task<ToDoItem> GetAsync(Guid id);
    Task<IEnumerable<ToDoItem>> GetItemsAsync();
    Task AddItemAsync(ToDoItem item);
    Task UpdateItemAsync(ToDoItem item);
    Task DeleteItemAsync(Guid id);
}
```

``` c#
public class ToDoItemService : IToDoItemService
{
    private readonly ToDoDbContext _dbContext;
    private readonly ILogger<ToDoItemService> _logger;

    public ToDoItemService(ToDoDbContext dbContext)
    {
        this._dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
    }

    public ToDoItemService(ToDoDbContext dbContext, ILogger<ToDoItemService> logger)
    {
        this._dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
        this._logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    public async Task<ToDoItem> GetAsync(Guid id)
    {
        return await _dbContext.ToDoItem.FindAsync(id);
    }

    public async Task<IEnumerable<ToDoItem>> GetItemsAsync()
    {
        return await _dbContext.ToDoItem.AsNoTracking().Select(s => s).ToListAsync();
    }

    public async Task AddItemAsync(ToDoItem item)
    {
        await _dbContext.ToDoItem.AddAsync(item);
        await _dbContext.SaveChangesAsync();
        _logger?.LogInformation($"{item.Name} created.");
    }

    public async Task DeleteItemAsync(Guid id)
    {
        var item = await _dbContext.ToDoItem.FindAsync(id);
        _dbContext.ToDoItem.Remove(item);
        await _dbContext.SaveChangesAsync();
        _logger?.LogInformation($"Item {item.Name} deleted.");
    }

    public async Task UpdateItemAsync(ToDoItem item)
    {
        var itemInDb = await _dbContext.ToDoItem.FindAsync(item.Id);
        itemInDb.Name = item.Name;
        await _dbContext.SaveChangesAsync();
        _logger?.LogInformation($"{item.Name} updated.");
    }
}
```

Now to test this controller we have to mock our service using Moq.
We can create a base class with a default mock of the service, which nearby
all unit tests are using and modify where needed.

``` c#
public abstract class BaseToDoControllerTests
{
    protected readonly List<ToDoItem> Items;
    protected readonly Mock<IToDoItemService> MockService;
    protected readonly ToDoController ControllerUnderTest;

    protected BaseToDoControllerTests(List<ToDoItem> items)
    {
        Items = items;
        MockService = new Mock<IToDoItemService>();
        MockService.Setup(svc => svc.GetItemsAsync())
            .ReturnsAsync(Items);
        ControllerUnderTest = new ToDoController(MockService.Object);
    }
}
```

Now we can write tests for our controller actions.

``` c#
public class IndexTests : BaseToDoControllerTests
{
    private static readonly ToDoItem FirstItem = new ToDoItem() { Id = Guid.NewGuid(), Name = "First Item" };
    private static readonly ToDoItem SecondItem = new ToDoItem() { Id = Guid.NewGuid(), Name = "Second Item" };

    public IndexTests() : base(new List<ToDoItem>() { FirstItem, SecondItem })
    {
    }

    [Fact]
    public async Task IndexGetViewModelShouldBeOfTypeIEnumerableToDoItem()
    {
        var result = await ControllerUnderTest.Index();

        var viewResult = Assert.IsType<ViewResult>(result);

        Assert.IsAssignableFrom<IEnumerable<ToDoItem>>(viewResult.ViewData.Model);
    }

    [Fact]
    public async Task IndexGetShouldReturnListOfToDoItems()
    {
        var result = await ControllerUnderTest.Index();

        var viewResult = Assert.IsType<ViewResult>(result);

        var model = Assert.IsAssignableFrom<IEnumerable<ToDoItem>>(viewResult.ViewData.Model);
        Assert.Equal(2, model.Count());
    }
}
```

``` c#
public class CreateTests : BaseToDoControllerTests
{
    private static readonly ToDoItem FirstItem = new ToDoItem() { Id = Guid.NewGuid(), Name = "First Item" };
    private static readonly ToDoItem SecondItem = new ToDoItem() { Id = Guid.NewGuid(), Name = "Second Item" };

    public CreateTests() : base(new List<ToDoItem>() { FirstItem, SecondItem })
    {
    }

    [Fact]
    public void CreateGetShouldHaveNoViewModel()
    {
        var result = ControllerUnderTest.Create();

        var viewResult = Assert.IsType<ViewResult>(result);

        Assert.Null(viewResult.ViewData.Model);
    }

    [Fact]
    public async Task CreatePostShouldReturnCreateViewModelIfModelIsInvalid()
    {
        var model = new CreateViewModel();
        ControllerUnderTest.ModelState.AddModelError("error", "testerror");

        var result = await ControllerUnderTest.Create(model);

        var viewResult = Assert.IsType<ViewResult>(result);
        Assert.IsAssignableFrom<CreateViewModel>(viewResult.ViewData.Model);
    }

    [Fact]
    public async Task CreatePostShouldReturnRedirectToActionIndexIfModelIsValid()
    {
        var model = new CreateViewModel();

        var result = await ControllerUnderTest.Create(model);

        var redirectResult = Assert.IsType<RedirectToActionResult>(result);
        Assert.Equal(nameof(ToDoController.Index), redirectResult.ActionName);
    }

    [Fact]
    public async Task CreatePostShouldCallAddItemAsyncOnceIfModelIsValid()
    {
        var model = new CreateViewModel() { Name = nameof(CreatePostShouldCallAddItemAsyncOnceIfModelIsValid) };

        await ControllerUnderTest.Create(model);

        MockService.Verify(mock => mock.AddItemAsync(It.IsAny<ToDoItem>()), Times.Once);
    }

    [Fact]
    public async Task CreatePostShouldCallAddItemAsyncWithCorrectParameterIfModelIsValid()
    {
        var item = new ToDoItem() { Name = nameof(CreatePostShouldCallAddItemAsyncWithCorrectParameterIfModelIsValid) };
        var model = new CreateViewModel() { Name = item.Name };

        await ControllerUnderTest.Create(model);

        MockService.Verify(mock => mock.AddItemAsync(It.Is<ToDoItem>(i => i.Name.Equals(item.Name))), Times.Once);
    }
}
```

``` c#
public class UpdateTests : BaseToDoControllerTests
{
    private static readonly ToDoItem FirstItem = new ToDoItem() { Id = Guid.NewGuid(), Name = "First Item" };
    private static readonly ToDoItem SecondItem = new ToDoItem() { Id = Guid.NewGuid(), Name = "Second Item" };

    public UpdateTests() : base(new List<ToDoItem>() { FirstItem, SecondItem })
    {
    }

    [Fact]
    public async Task UpdateGetWithInvalidIdShouldReturnNotFound()
    {
        var result = await ControllerUnderTest.Update(Guid.Empty);

        Assert.IsType<NotFoundResult>(result);
    }

    [Fact]
    public async Task UpdateGetShouldCallGetAsyncOnce()
    {
        await ControllerUnderTest.Update(Guid.Empty);

        MockService.Verify(mock => mock.GetAsync(It.IsAny<Guid>()), Times.Once);
    }

    [Fact]
    public async Task UpdateGetViewModelShouldBeOfTypeUpdateViewModel()
    {
        MockService.Setup(svc => svc.GetAsync(FirstItem.Id)).ReturnsAsync(FirstItem);

        var result = await ControllerUnderTest.Update(FirstItem.Id);

        var viewResult = Assert.IsType<ViewResult>(result);
        Assert.IsAssignableFrom<UpdateViewModel>(viewResult.ViewData.Model);
    }

    [Fact]
    public async Task UpdateGetViewModelShouldHaveCorrectProperties()
    {
        MockService.Setup(svc => svc.GetAsync(FirstItem.Id)).ReturnsAsync(FirstItem);

        var result = await ControllerUnderTest.Update(FirstItem.Id);

        var viewResult = Assert.IsType<ViewResult>(result);
        var viewModel = Assert.IsAssignableFrom<UpdateViewModel>(viewResult.ViewData.Model);
        Assert.Equal(FirstItem.Id, viewModel.Id);
        Assert.Equal(FirstItem.Name, viewModel.Name);
    }

    [Fact]
    public async Task UpdatePostShouldReturnUpdateViewModelIfModelIsInvalid()
    {
        var model = new UpdateViewModel();

        ControllerUnderTest.ModelState.AddModelError("error", "testerror");
        var result = await ControllerUnderTest.Update(model);

        var viewResult = Assert.IsType<ViewResult>(result);
        Assert.IsAssignableFrom<UpdateViewModel>(viewResult.ViewData.Model);
    }

    [Fact]
    public async Task UpdatePostShouldReturnRedirectToActionIndexIfModelIsValid()
    {
        var model = new UpdateViewModel();

        var result = await ControllerUnderTest.Update(model);

        var redirectResult = Assert.IsType<RedirectToActionResult>(result);
        Assert.Equal(nameof(ToDoController.Index), redirectResult.ActionName);
    }

    [Fact]
    public async Task UpdatePostShouldCallUpdateItemAsyncOnceIfModelIsValid()
    {
        var model = new UpdateViewModel() { Name = nameof(UpdatePostShouldCallUpdateItemAsyncOnceIfModelIsValid) };

        await ControllerUnderTest.Update(model);

        MockService.Verify(mock => mock.UpdateItemAsync(It.IsAny<ToDoItem>()), Times.Once);
    }

    [Fact]
    public async Task UpdatePostShouldCallUpdateItemAsyncWithCorrectParameterIfModelIsValid()
    {
        var item = new ToDoItem() { Id = FirstItem.Id, Name = nameof(UpdatePostShouldCallUpdateItemAsyncWithCorrectParameterIfModelIsValid) };
        var model = new UpdateViewModel() { Id = item.Id, Name = item.Name };

        await ControllerUnderTest.Update(model);

        MockService.Verify(mock => mock.UpdateItemAsync(It.Is<ToDoItem>(i => i.Name.Equals(item.Name) && i.Id.Equals(item.Id))), Times.Once);
    }
}
```

``` c#
public class DeleteTests : BaseToDoControllerTests
{
    private static readonly ToDoItem FirstItem = new ToDoItem() { Id = Guid.NewGuid(), Name = "First Item" };
    private static readonly ToDoItem SecondItem = new ToDoItem() { Id = Guid.NewGuid(), Name = "Second Item" };

    public DeleteTests() : base(new List<ToDoItem>() { FirstItem, SecondItem })
    {
    }

    [Fact]
    public async Task DeleteGetWithInvalidIdShouldReturnNotFound()
    {
        var result = await ControllerUnderTest.Delete(Guid.Empty);

        Assert.IsType<NotFoundResult>(result);
    }

    [Fact]
    public async Task DeleteGetShouldCallGetAsyncOnce()
    {
        await ControllerUnderTest.Delete(Guid.Empty);

        MockService.Verify(mock => mock.GetAsync(It.IsAny<Guid>()), Times.Once);
    }

    [Fact]
    public async Task DeleteGetViewModelShouldBeOfTypeDeleteViewModel()
    {
        MockService.Setup(svc => svc.GetAsync(FirstItem.Id)).ReturnsAsync(FirstItem);

        var result = await ControllerUnderTest.Delete(FirstItem.Id);

        var viewResult = Assert.IsType<ViewResult>(result);
        Assert.IsAssignableFrom<DeleteViewModel>(viewResult.ViewData.Model);
    }

    [Fact]
    public async Task DeleteGetViewModelShouldHaveCorrectProperties()
    {
        MockService.Setup(svc => svc.GetAsync(FirstItem.Id)).ReturnsAsync(FirstItem);

        var result = await ControllerUnderTest.Delete(FirstItem.Id);

        var viewResult = Assert.IsType<ViewResult>(result);
        var viewModel = Assert.IsAssignableFrom<DeleteViewModel>(viewResult.ViewData.Model);
        Assert.Equal(FirstItem.Id, viewModel.Id);
        Assert.Equal(FirstItem.Name, viewModel.Name);
    }

    [Fact]
    public async Task DeletePostShouldReturnRedirectToActionIndex()
    {
        var model = new DeleteViewModel();

        var result = await ControllerUnderTest.Delete(model);

        var redirectResult = Assert.IsType<RedirectToActionResult>(result);
        Assert.Equal(nameof(ToDoController.Index), redirectResult.ActionName);
    }

    [Fact]
    public async Task DeletePostShouldCallDeleteItemAsyncOnceIfModelIsValid()
    {
        var model = new DeleteViewModel() { Name = nameof(DeletePostShouldCallDeleteItemAsyncOnceIfModelIsValid) };

        await ControllerUnderTest.Delete(model);

        MockService.Verify(mock => mock.DeleteItemAsync(It.IsAny<Guid>()), Times.Once);
    }

    [Fact]
    public async Task DeletePostShouldCallDeleteItemAsyncWithCorrectParameter()
    {
        var item = new ToDoItem() { Id = FirstItem.Id, Name = nameof(DeletePostShouldCallDeleteItemAsyncWithCorrectParameter) };
        var model = new DeleteViewModel() { Id = item.Id, Name = item.Name };

        await ControllerUnderTest.Delete(model);

        MockService.Verify(mock => mock.DeleteItemAsync(It.Is<Guid>(id => id.Equals(item.Id))), Times.Once);
    }
}
```

The project is available on [github][2]{:target="_blank"}.

Useful links

* [Testing Controllers][3]{:target="_blank"}
* [Unit Testing with XUnit][4]{:target="_blank"}

[1]: https://github.com/moq/moq
[2]: https://github.com/raaaimund/ToDo
[3]: https://docs.microsoft.com/en-us/aspnet/core/mvc/controllers/testing?view=aspnetcore-2.2
[4]: https://docs.microsoft.com/en-us/dotnet/core/testing/unit-testing-with-dotnet-test