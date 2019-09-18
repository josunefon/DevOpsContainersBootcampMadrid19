FROM mcr.microsoft.com/dotnet/core/aspnet:2.2-nanoserver-1809 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/core/sdk:2.2-nanoserver-1809 AS build
WORKDIR /src
COPY ["DotNetCoreSqlDb.csproj", ""]
RUN dotnet restore "./DotNetCoreSqlDb.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "DotNetCoreSqlDb.csproj" -c Release -o /app

FROM build AS publish
RUN dotnet publish "DotNetCoreSqlDb.csproj" -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=publish /app .
ENTRYPOINT ["dotnet", "DotNetCoreSqlDb.dll"]