<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# I made a location for postgresql to store data, is there something I need to do to prepare the location / file direcotyr?

When you create a custom location for PostgreSQL to store its data, such as `/home/ewt/postgresql/data`, you need to prepare the directory with the following steps:

1. **Create the directory if it doesn't exist:**

```bash
mkdir -p /home/ewt/postgresql/data
```

2. **Set ownership to the `postgres` user and group:**
PostgreSQL runs under the `postgres` system user by default in NixOS, so this user needs ownership to read and write data.

```bash
chown -R postgres:postgres /home/ewt/postgresql/data
```

3. **Set correct permissions:**
Restrict access properly by allowing only the owner to read/write/execute:

```bash
chmod 700 /home/ewt/postgresql/data
```

4. **Ensure parent directories are accessible:**
For the `postgres` user to access the data directory, each parent directory in the path (`/home/ewt` and `/home/ewt/postgresql`) must have execute (`x`) permissions for `postgres` user. For example:

```bash
chmod o+x /home/ewt
chmod o+x /home/ewt/postgresql
```

or alternatively adjust group permissions and add `postgres` user to that group.
5. **Initialize the database in the directory:**
Use the `initdb` command as the `postgres` user to initialize the PostgreSQL data directory:

```bash
sudo -u postgres initdb -D /home/ewt/postgresql/data
```

6. **Start the PostgreSQL service:**
Using NixOS service management, rebuild and start your service, making sure your NixOS config points to the correct `dataDir`:

```
sudo nixos-rebuild switch
sudo systemctl start postgresql
```


In short, you need to create and correctly own the PostgreSQL data directory, ensure the `postgres` user can traverse parent directories, initialize the database cluster using `initdb` in that location, and then start the service. This preparation ensures PostgreSQL can read/write its files without permission errors on startup or operation.[^1][^2][^4]
<span style="display:none">[^3][^5][^6][^7][^8][^9]</span>

<div align="center">⁂</div>

[^1]: https://stackoverflow.com/questions/74742410/how-to-use-postgresql-in-nixos

[^2]: https://kevincox.ca/2025/08/24/nixos-postgres-upgrade/

[^3]: https://www.johbo.com/2017/on-demand-postgresql-for-your-development-environment.html

[^4]: https://wiki.nixos.org/wiki/PostgreSQL

[^5]: https://beb.ninja/post/postgres-local/

[^6]: https://mgdm.net/weblog/postgresql-in-a-nix-shell/

[^7]: https://discourse.nixos.org/t/set-up-a-simple-postgres-instance/60280

[^8]: https://www.reddit.com/r/NixOS/comments/1ise8iy/how_do_i_move_datadirs_by_changing_a_nix/

[^9]: https://mynixos.com/nix-darwin/options/services.postgresql

