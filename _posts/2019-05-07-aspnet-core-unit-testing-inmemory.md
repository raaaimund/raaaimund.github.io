---
layout:     post
title:      Unit testing in ASP.NET Core with EF Sqlite in-memory and XUnit
date:       2019-05-07 20:00:00
author:     Raimund Rittnauer
summary:    A simple example how to do unit testing in ASP.NET Core with Entity Framework Core Sqlite in-memory database and XUnit
categories: tech
comments: true
tags:
 - unit testing
 - asp.net
 - sqlite
 - in-memory
 - entity framework
 - xunit
---

Just a litte example how to use [Entity Framework Core Sqlite Provider][1]{:target="_blank"} in-memory database together with simple unit testing in ASP.NET Core and XUnit.

Lets assume we have the following setup.

An Entity Framework Core DbContext *ToDoDbContext*

``` c#
public class ToDoDbContext : DbContext
{
    public DbSet<ToDoItem> ToDoItem { get; set; }

    public ToDoDbContext(DbContextOptions<ToDoDbContext> options)
        : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(ToDoDbContext).Assembly);
    }
}
```

and a configuration *ToDoItemConfiguration*

``` c#
class ToDoItemConfiguration : IEntityTypeConfiguration<ToDoItem>
{
    public void Configure(EntityTypeBuilder<ToDoItem> builder)
    {
        builder.HasKey(k => k.Id);
        builder.Property(p => p.Id).IsRequired().ValueGeneratedOnAdd();
        builder.Property(p => p.Name).IsRequired().HasMaxLength(128);
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

To test our configuration with an in-memory database we can use the [Entity Framework Core Sqlite Provider][1]{:target="_blank"}. There is also an [InMemory Provider for testing][2]{:target="_blank"} but 

> InMemory is designed to be a general purpose database for testing, and is not designed to mimic a relational database.

In our test project, we can create a base class for creating and disposing the in-memory Sqlite database.

``` c#
public abstract class TestWithSqlite : IDisposable
{
    private const string InMemoryConnectionString = "DataSource=:memory:";
    private readonly SqliteConnection _connection;

    protected readonly ToDoDbContext DbContext;

    protected TestWithSqlite()
    {
        _connection = new SqliteConnection(InMemoryConnectionString);
        _connection.Open();
        var options = new DbContextOptionsBuilder<ToDoDbContext>()
                .UseSqlite(_connection)
                .Options;
        DbContext = new ToDoDbContext(options);
        DbContext.Database.EnsureCreated();
    }

    public void Dispose()
    {
        _connection.Close();
    }
}
```

Now we can create our unit tests for our configuration

``` c#
public class ToDoItemConfigurationTests : TestWithSqlite
{
    [Fact]
    public void TableShouldGetCreated()
    {
        Assert.False(DbContext.ToDoItem.Any());
    }

    [Fact]
    public void NameIsRequired()
    {
        var newItem = new ToDoItem();
        DbContext.ToDoItem.Add(newItem);

        Assert.Throws<DbUpdateException>(() => DbContext.SaveChanges());
    }

    [Fact]
    public void AddedItemShouldGetGeneratedId()
    {
        var newItem = new ToDoItem() { Name = "Testitem" };
        DbContext.ToDoItem.Add(newItem);
        DbContext.SaveChanges();

        Assert.NotEqual(Guid.Empty, newItem.Id);
    }

    [Fact]
    public void AddedItemShouldGetPersisted()
    {
        var newItem = new ToDoItem() { Name = "Testitem" };
        DbContext.ToDoItem.Add(newItem);
        DbContext.SaveChanges();

        Assert.Equal(newItem, DbContext.ToDoItem.Find(newItem.Id));
        Assert.Equal(1, DbContext.ToDoItem.Count());
    }
}
```

The project is available on [github][3]{:target="_blank"}.

[1]: https://docs.microsoft.com/en-us/ef/core/providers/sqlite/
[2]: https://docs.microsoft.com/en-us/ef/core/miscellaneous/testing/in-memory
[3]: https://github.com/raaaimund/ToDo