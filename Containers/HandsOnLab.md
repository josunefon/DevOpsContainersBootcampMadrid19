## Introduction
El contexto de este apartado sería, tenemos ya una aplicación .net core que funciona tanto en local como en Azure y queremos containerizarla. Para ello:

## Steps to follow

1. El primer paso a realizar es crearnos un fichero sin extensión que tenga como nombre Dockerfile. Este fichero debe situarse en la raíz de nuestro proyecto.
   
2. El primer bloque de nuestro fichero constará de las siguientes líneas:
   
		FROM mcr.microsoft.com/dotnet/core/aspnet:2.2-nanoserver-1809 AS base
		WORKDIR /app
		EXPOSE 80

En la primera línea estamos indicando que nuestra aplicación va a correr sobre una base que es dotnet core 2.2. Para poder funcionar necesitamos que Docker se descargue una imagen donde ya exista este SDK. Como no hsmoe especificado el origen de esta imagen, por defecto hará el pull del Docker Registry público.

En la segunda línea le indicamos que, dentro del contenedor, el directorio donde vamos a trabajar es el /app.

Por último, con el tag EXPOSE, indicamos que el puerto que debe exponer la aplicación dentro del contenedor es el 80. 

	
3. Una vez que tenemos una primera versión de nuestro Dockerfile, es importante generar imágenes de manera progresiva y versionada. Esto nos permitirá ver cómo la imagen va variando a medida que vamos introduciendo más comandos. El comando que debemos utilizar para generar la imagen es el siguiente:

![containers1](./img/containers1.png)	
	
		docker build -t myimage:initial -f Dockerfile .

La syntaxis de este comando indica que vamos a construir una imagen que se va a llamar myimage, con una tag que vamos a llamar initial y que debe construirse a partir del Dockerfile que se encuentra en la raíz.

![containers2](./img/containers2.png)	
	
Si nos fijamos veremos que lo ha creado con el tag initial porque, cuando hemos metido el comando. Todo debería tener control de versiones a través del tag. Por defecto, si no se dice nada el tag es **latest**.
	
4. Comprobamos que efectivamente tenemos esa imagen con el comando:
   
		docker images

![containers3](./img/containers3.png)	

Ahora mismo tenemos esa imagen creada en local. Es decir, sólo nosotros la podemos desplegar.

5. Lo que podemos ver es que tenemos dos imágenes creadas, una es la imagen de base con dotnet 2.2 y la otra es la que nos ha creado a partir del hub. En caso de que la única línea que hubiesemos puesto en el fichero hubiese sido la primera, indicando cuál es la imagen base, el id de las imágenes sería el mismo porque serían dos copias exactas. Como hemos cambiado algunos parámetros como el puerto en el que expondremos esta imagen y el directorio donde vamos a trabajar, el id cambia porque la imagen es ligeramente distinta. 
	
Si hacemos un **docker image inspect myimage:initial** podemos ver los datos de la imagen que acabamos de generar con las capas. 
	
![containers4](./img/containers4.png)		

En este caso tenemos ocho layers que definen los cambios que se han configurado en nuestra imagen.
	
6. Añadimos más configuraciones al docker file. El siguiente grupo define que tiene que utilizar el sdk que ya va incluido en la imagen que se ha descargado anteriormente, que tiene que copiar el fichero de proyecto al directorio de trabajo del contenedor /src y le pide que corra un restore y un build de la aplicación.
	
		FROM mcr.microsoft.com/dotnet/core/sdk:2.2-nanoserver-1809 AS build
		WORKDIR /src
		COPY ["DotNetCoreSqlDb.csproj", ""]
		RUN dotnet restore "./DotNetCoreSqlDb.csproj"
		COPY . .
		WORKDIR "/src/."
		RUN dotnet build "DotNetCoreSqlDb.csproj" -c Release -o /app
		
Volvemos a crear la imagen pero con un tag nuevo, en este caso será build.

![containers5](./img/containers5.png)	

Comprobamos ahora las layers.

![containers6](./img/containers6.png)		
	
Estas nuevas layers que se han formado representan los cambios que hemos aplicado a la imagen del contenedor.
	
7. El siguiente bloque es que el hace el publish de nuestra aplicación. Para ello toma como base la imagen que ha nombrado build en el bloque anterior y guarda esta nueva modificación como publish.
	
		FROM build AS publish
		RUN dotnet publish "DotNetCoreSqlDb.csproj" -c Release -o /app

![containers7](./img/containers7.png)			
				
8. El último bloque copia todo lo que se ha publicado en el directorio /app del contenedor y expone ese contenido como un ejecutable utilizando para ello un ENTRYPOINT. Mientras ese entrypoint este activo podremos ejecutar la aplicación dentro del contenedor. En el momento en el que lo paremos la aplicación deja de estar disponible. 
	
		FROM base AS final
		WORKDIR /app
		COPY --from=publish /app .
		ENTRYPOINT ["dotnet", "DotNetCoreSqlDb.dll"]
		
![containers8](./img/containers8.png)			

9. Veamos todas las imágenes versionadas que hemos ido generando.
	
![containers9](./img/containers9.png)		
		
10. Ejecutamos el contenedor.
	
	Docker run --name myapp -p 82:80 -d myimage:final

![containers10](./img/containers10.png)		

![containers11](./img/containers11.png)		

En el comando anterior lo que podemos ver es que, utilizando el tag -p indicamos un cambio de puertos. En concreto lo que se indica es que queremos publicar en el puerto 82 lo que el contenedor está publicando en el puerto 80. Esta funcionalidad es muy útil si tenemos varias aplicaciones que se publican por defecto en el puerto 80 y las queremos correr a la vez.	

11.  Por defecto, tal y como tenemos el proyecto descargado de git, el código va a almacenar los datos en la base datos que tiene en local. Sin embargo, si queremos que esta aplicación sea persistente y utilizar así una base de datos que tenemos creada en nuestra cuenta de Azure, podemos hacer los siguientes cambios en el proyecto.

En el Starup.cs

            if (Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") == "Production")
                services.AddDbContext<MyDatabaseContext>(options =>
                        options.UseSqlServer(Configuration.GetConnectionString("MyDbConnection")));
            else
                services.AddDbContext<MyDatabaseContext>(options =>
                        options.UseSqlite("Data Source=localdatabase.db"));

En el appsettings.json
	
	"ConnectionStrings": {
	    "MyDbConnection": "Server=tcp:masanzdesqlsrvdev01.database.windows.net,1433;Initial Catalog=coreDB;Persist Security Info=False;User ID=bootcampdev;Password=Microsoft$20;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
	  }

Tendríamos que comentar y descomentar este código en función de lo que queramos que muestre y así podríamos ver los datos que tenemos guardados en local/nube.



		
		
		
		
		
