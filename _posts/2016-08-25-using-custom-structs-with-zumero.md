---
layout:     post
title:      Using custom structs with Zumero
date:       2016-08-25 22:30:00
author:     Raimund Rittnauer
description:    How to use Guid, DateTime, Decimal and other structs with Zumero
categories: tech
thumbnail:  code
comments: true
tags:
 - zumero
 - guid
 - datetime
 - decimal
 - struct
 - c#
---

We are using [Zumero for SQL Server (ZSS)][1]{:target="_blank"} as our library for the synchronisation of the local SQLite database of each android device with a remote MSSQL database.
One of the main issues was that Zumero needs a different representation of specific data types and to access the data you have to encode and decode it everytime.

I used these data types on my MSSQL database and Zumero encoded these data types to

* UNIQUEIDENTIFIER (MSSQL) -> byte[] (SQLite)
  * Guid in C#
* DateTime (MSSQL) -> string (SQLite)
  * DateTime in C#
  * with format "yyyy-MM-dd HH:mm:ss.fff"
* Decimal (MSSQL) -> long (SQLite)
  * decimal in C#
  * for example in MSSQL DECIMAL(10, 6) you have to use the scale of Math.Pow(10, 6) to encode it to long and decode it from long

The [ZSS App Generator (ZAG)][2]{:target="_blank"} is a great tool to get insights and it generates code for encoding and decoding these data types for you, but if you have only more than one Guid, DateTime or decimal property in your model, your code is getting bigger and bigger. For a simple Guid property the following code is generated.

{% highlight ruby %}

[PrimaryKey]
[NotNull]
[Column("Id")]

public byte[] Id_raw { get; set; }

public static string Id_PropertyName = "Id";

[Ignore]
public Guid Id
{ 
  get { return (Id_raw != null) ? new Guid(Id_raw) : Id = Guid.NewGuid(); } 
  set { SetProperty(Id_raw, Id_ConvertToBytes(value), (val) => { Id_raw = val; }, Id_PropertyName); }
}

public static byte[] Id_ConvertToBytes(Guid guid)
{
  return guid.ToByteArray();
}

{% endhighlight %}

You see that a Guid is stored as a byte array and the code for encoding and decoding is generated for every Guid, DateTime and decimal property.

I wanted to reduce the code and started trying to create my own structs for these three structs which do automatic encoding and decoding.
I ended up implementing these three structs

* Guid -> ZumeroGuid
* DateTime -> ZumeroDateTime
* Decimal -> ZumeroDecimal

With these structs you only need one line of code for your property in your model classes and the encoding and decoding is done automatically from the struct.

{% highlight ruby %}

[PrimaryKey]
[NotNull]
public ZumeroGuid Id { get; set; }

{% endhighlight %}

It took some time to figure out what I need and how to implement these structs and also that there are no issues using them with Zumero and SQLite.Net.
I am very happy, that I found a great blog post from [Singular][3]{:target="_blank"} which helped me a lot and that SQLite.Net offers the interface [ISerializeable[4]{:target="_blank"}.

The code and a short description is available on [github][5]{:target="_blank"}.

Finally I have to figure out why I have to implement IConvertible. Without this interface SQLite.Net will throw an exception, but I dont have to implement any of the methods and
SQLite.Net also isn't using these methods.

## ZumeroStructs in action

### ZumeroGuid

_From_
{% highlight ruby %}

[PrimaryKey]
[NotNull]
[Column("Id")]

public byte[] Id_raw { get; set; }

public static string Id_PropertyName = "Id";

[Ignore]
public Guid Id
{ 
  get { return (Id_raw != null) ? new Guid(Id_raw) : Id = Guid.NewGuid(); } 
  set { SetProperty(Id_raw, Id_ConvertToBytes(value), (val) => { Id_raw = val; }, Id_PropertyName); }
}

public static byte[] Id_ConvertToBytes(Guid guid)
{
  return guid.ToByteArray();
}

{% endhighlight %}

_To_
{% highlight ruby %}

[PrimaryKey]
[NotNull]
public ZumeroGuid Id { get; set; }

{% endhighlight %}

### ZumeroDateTime
_From_
{% highlight ruby %}

[NotNull]
[Column("Time")]

public string Time_raw { get; set; }

public static string Time_PropertyName = "Time";

[Ignore]
public DateTime Time
{
  get { return Time_raw != null ? DateTime.Parse(Time_raw) : Time = DateTime.Now; }
  set { SetProperty(Time_raw, Time_ConvertToString(value), (val) => { Time_raw = val; }, Time_PropertyName); }
}

public static string Time_ConvertToString(DateTime date)
{
  return date.ToString("yyyy-MM-dd HH:mm:ss.fff");
}

{% endhighlight %}

_To_
{% highlight ruby %}

[NotNull]
public ZumeroDateTime Time { get; set; }

{% endhighlight %}

### ZumeroDecimal
_From_
{% highlight ruby %}

[NotNull]
[Column("Lat")]

public long Lat_raw { get; set; }

private static long _Lat_scale = (long)Math.Pow(10, 6);

public static string Lat_PropertyName = "Lat";

[Ignore]
public decimal Lat
{ 
  get { return (decimal)Lat_raw / (decimal)_Lat_scale; }
  set { SetProperty(Lat_raw, Lat_ConvertToInt(value), (val) => { Lat_raw = val; }, Lat_PropertyName); }
}

public static long Lat_ConvertToInt(decimal arg_Lat)
{
  return (long)Math.Floor((double)(arg_Lat * (decimal)_Lat_scale));
}

{% endhighlight %}

_To_
{% highlight ruby %}

[NotNull]
public ZumeroDecimal Lat { get; set; }

{% endhighlight %}

[1]: http://zumero.com/
[2]: http://zumero.com/dev-center/zss/
[3]: http://www.singular.co.nz/2007/12/shortguid-a-shorter-and-url-friendly-guid-in-c-sharp/
[4]: https://github.com/oysteinkrog/SQLite.Net-PCL/blob/master/src/SQLite.Net/ISerializable.cs
[5]: https://github.com/raaaimund/ZumeroHelper