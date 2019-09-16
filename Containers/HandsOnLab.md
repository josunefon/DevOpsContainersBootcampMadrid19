## Introduction

The context of this section would be, we already have a .net core application that works both locally and in Azure and we want to containerize it. For it:

## Steps to follow

1. The first step to perform is to create a file without an extension that has the name Dockerfile. This file must be at the root of our project.
   
2. The first block of our file will consist of the following lines:
   
		FROM mcr.microsoft.com/dotnet/core/aspnet:2.2-nanoserver-1809 AS base
		WORKDIR /app
		EXPOSE 80

In the first line we are indicating that our application will run on a basis that is dotnet core 2.2. In order to work we need Docker to download an image where this SDK already exists. Since the origin of this image has not been specified, by default it will pull it from the public Docker Registry.

In the second line we indicate that, within the container, the directory where we are going to work is the / app.

Finally, with the EXPOSE tag, we indicate that the port that the application must expose inside the container is 80. 

	
3. Once we have a first version of our Dockerfile, it is important to generate images in a progressive and versioned way. This will allow us to see how the image varies as we enter more commands. The command that we must use to generate the image is the following:

![containers1](./img/containers1.png)	
	
		docker build -t myimage:initial -f Dockerfile .

The syntax of this command indicates that we are going to build an image that is going to be called myimage, with a tag that we are going to call initial and that must be constructed from the Dockerfile that is in the root.

![containers2](./img/containers2.png)	
	
Everything should have version control through the tag. By default, if nothing is said, the tag is **latest**.
	
4. We check that we actually have that image with the command:
   
		docker images

![containers3](./img/containers3.png)	

Right now we have that image created locally. That is, only we can deploy it.

What we can see is that we have two images created, one is the base image with dotnet 2.2 and the other is the one that created us from the hub. If the only line we had put in the file would have been the first, indicating which is the base image, the id of the images would be the same because they would be two exact copies. As we have changed some parameters such as the port where we will expose this image and the directory where we are going to work, the id changes because the image is slightly different.

5. If we type **docker image inspect myimage:initial** we can see the different layers generated withing the image. 
	
![containers4](./img/containers4.png)		

In this case we have eight layers that define the changes that have been configured in our image.
	
6. We add more settings to the docker file. The following group defines that you have to use the sdk that is already included in the image that has been previously downloaded, that you have to copy the project file to the working directory of the / src container and ask you to run a restore and a build of the application.
	
		FROM mcr.microsoft.com/dotnet/core/sdk:2.2-nanoserver-1809 AS build
		WORKDIR /src
		COPY ["DotNetCoreSqlDb.csproj", ""]
		RUN dotnet restore "./DotNetCoreSqlDb.csproj"
		COPY . .
		WORKDIR "/src/."
		RUN dotnet build "DotNetCoreSqlDb.csproj" -c Release -o /app
		
We recreate the image but with a new tag, in this case it will be **build**.

![containers5](./img/containers5.png)	

Lets check the layers.

![containers6](./img/containers6.png)		
	
These new layers that have been created represent the changes we have applied to the image of the container.
	
7. The next block is the one that publishes our application. This is based on the image named build in the previous block and saves this new modification as publish.
	
		FROM build AS publish
		RUN dotnet publish "DotNetCoreSqlDb.csproj" -c Release -o /app

![containers7](./img/containers7.png)			
				
8. The last block copies everything that has been published in the container / app directory and exposes that content as an executable using an ENTRYPOINT. While that entrypoint is active we can execute the application inside the container. At the moment we stop it, the application is no longer available.
	
		FROM base AS final
		WORKDIR /app
		COPY --from=publish /app .
		ENTRYPOINT ["dotnet", "DotNetCoreSqlDb.dll"]
		
![containers8](./img/containers8.png)			

9. Let's see all the versioned images that we have been generating.
	
![containers9](./img/containers9.png)		
		
10. We run the container using the following command.
	
	Docker run --name myapp -p 82:80 -d myimage:final

![containers10](./img/containers10.png)		

![containers11](./img/containers11.png)		

In the previous command what we can see is that, using the -p tag we indicate a change of ports. Specifically, what is indicated is that we want to publish on port 82 what the container is publishing on port 80. This functionality is very useful if we have several applications that are published by default on port 80 and we want to run them at the same time .	

11.  By default, as we have the project downloaded from git, the code will store the data in the database that you have locally. However, if we want this application to be persistent and thus use a database that we have created in our Azure account, we can make the following changes in the project.

At the Starup.cs file:

            if (Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") == "Production")
                services.AddDbContext<MyDatabaseContext>(options =>
                        options.UseSqlServer(Configuration.GetConnectionString("MyDbConnection")));
            else
                services.AddDbContext<MyDatabaseContext>(options =>
                        options.UseSqlite("Data Source=localdatabase.db"));

At the appsettings.json file:
	
	"ConnectionStrings": {
	    "MyDbConnection": "Server=tcp:masanzdesqlsrvdev01.database.windows.net,1433;Initial Catalog=coreDB;Persist Security Info=False;User ID=bootcampdev;Password=Microsoft$20;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
	  }

We would have to comment and uncomment this code based on what we want it to show and so we could see the data we have stored locally or in the cloud.



		
		
		
		
		
