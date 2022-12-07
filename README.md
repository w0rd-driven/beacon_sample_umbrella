# BeaconSample.Umbrella

## Summary

This is a sample project, following the instruction steps from [https://github.com/BeaconCMS/beacon](https://github.com/BeaconCMS/beacon).
It is meant to get you up and running quickly. Note that because the CMS is in flux that things may break in unexpected ways.

We'll be upgrading somewhat slowly or possibly creating multiple prototypes as this is currently my 3rd iteration of following along.

I also have planned a series of blog posts to dive a deeper into how Beacon currently works with some approaches from other ecosystems.

Series:

1. [Introduction to DockYard Beacon CMS](https://braytonium.com/2022/12/01/dock-yard-beacon-cms/)

## Installation

### Steps

1. Create a top-level directory to keep our application pair. This is temporary as the project matures.
    1. `mkdir beacon_sample`
2. Clone [GitHub - BeaconCMS/beacon: Beacon CMS](https://github.com/BeaconCMS/beacon) to `./beacon`.
    1. `git clone git@github.com:BeaconCMS/beacon.git`
3. Start with our first step from the Readme
    1. Create an umbrella phoenix app
    2. `mix phx.new --umbrella --install beacon_sample`
4. Go to the umbrella project directory
    1. `cd beacon_sample/`
5. Initialize git
    1. `git init`
6. Commit the freshly initialized project
    1. `Initial commit of Phoenix v1.6.15`  as of the time of this writing.
    2. I prefer to capture the version and everything scaffolded as-is. This allows us to revert back to the pristine state if we ever need to.
7. `Add :beacon as a dependency to both apps in your umbrella project`

    ```elixir
    # Local:
    {:beacon, path: "../../../beacon"},
    # Or from GitHub:
    {:beacon, github: "beaconCMS/beacon"},
    ```

    1. Add to `apps/beacon_sample/mix.exs` and `apps/beacon_sample_web/mix.exs` under the section `defp deps do`.
    2. We choose the local version to override commits as needed. When the project solidifies, the GitHub repository will be far more ideal.
    3. I'll want to research the git dependency as I believe we can specify commits? There's possibly no need to have a local revision at all.
8. Run `mix deps.get` to install the dependencies.
9. Commit the changes.
    1. `Add :beacon as a dependency to both apps in your umbrella project` seems like a good enough commit message.
10. `Configure Beacon Repo`
    1. Add the `Beacon.Repo` under the `ecto_repos:` section in `config/config.exs`.
    2. Configure the database in `dev.exs`. We'll do production later.

        ```elixir
        # Configure beacon database
        config :beacon, Beacon.Repo,
        username: "postgres",
        password: "postgres",
        database: "beacon_sample_beacon",
        hostname: "localhost",
        show_sensitive_data_on_connection_error: true,
        pool_size: 10

        ```

11. Commit the changes.
    1. `Configure Beacon Repo` subject with `Configure the beacon repository in our dev only environment for now.` body.
12. `Create a BeaconDataSource module that implements Beacon.DataSource.Behaviour`
    1. Create `apps/beacon_sample/lib/beacon_sample/datasource.ex`

        ```elixir
        defmodule BeaconSample.BeaconDataSource do
          @behaviour Beacon.DataSource.Behaviour
        
          def live_data("my_site", ["home"], _params), do: %{vals: ["first", "second", "third"]}
          def live_data("my_site", ["blog", blog_slug], _params), do: %{blog_slug_uppercase: String.upcase(blog_slug)}
          def live_data(_, _, _), do: %{}
        end
        ```

    2. Add that DataSource to your `config/config.exs`

        ```elixir
        config :beacon,
          data_source: BeaconSample.BeaconDataSource
        
        ```

13. Commit the changes.
    1. `Configure BeaconDataSource`
14. Make router (`apps/beacon_sample_web/lib/beacon_sample_web/router.ex`) changes to cover Beacon pages.
    1. Add a `:beacon` pipeline. I typically do this towards the pipeline sections at the top, starting at line 17.

        ```elixir
        pipeline :beacon do
          plug BeaconWeb.Plug
        end
        ```

    2. Add a `BeaconWeb` scope.

        ```elixir
        scope "/", BeaconWeb do
          pipe_through :browser
          pipe_through :beacon
        
          live_session :beacon, session: %{"beacon_site" => "my_site"} do
            live "/beacon/*path", PageLive, :path
          end
        end
        ```

    3. Comment out existing scope.

        ```elixir
        # scope "/", BeaconSampleWeb do
        #   pipe_through :browser

        #   get "/", PageController, :index
        # end
        ```

15. Commit the changes.
    1. `Add routing changes`
16. Add some components to your `apps/beacon_sample/priv/repo/seeds.exs`.

    ```elixir
    alias Beacon.Components
    alias Beacon.Pages
    alias Beacon.Layouts
    alias Beacon.Stylesheets
    
    Stylesheets.create_stylesheet!(%{
      site: "my_site",
      name: "sample_stylesheet",
      content: "body {cursor: zoom-in;}"
    })
    
    Components.create_component!(%{
      site: "my_site",
      name: "sample_component",
      body: """
      <li>
        <%= @val %>
      </li>
      """
    })
    
    %{id: layout_id} =
      Layouts.create_layout!(%{
        site: "my_site",
        title: "Sample Home Page",
        meta_tags: %{"foo" => "bar"},
        stylesheet_urls: [],
        body: """
        <header>
          Header
        </header>
        <%= @inner_content %>
    
        <footer>
          Page Footer
        </footer>
        """
      })
    
    %{id: page_id} =
      Pages.create_page!(%{
        path: "home",
        site: "my_site",
        layout_id: layout_id,
        template: """
        <main>
          <h2>Some Values:</h2>
          <ul>
            <%= for val <- @beacon_live_data[:vals] do %>
              <%= my_component("sample_component", val: val) %>
            <% end %>
          </ul>
          <.form let={f} for={:greeting} phx-submit="hello">
            Name: <%= text_input f, :name %> <%= submit "Hello" %>
          </.form>
          <%= if assigns[:message], do: assigns.message %>
        </main>
        """
      })
    
    Pages.create_page!(%{
      path: "blog/:blog_slug",
      site: "my_site",
      layout_id: layout_id,
      template: """
      <main>
        <h2>A blog</h2>
        <ul>
          <li>Path Params Blog Slug: <%= @beacon_path_params.blog_slug %></li>
          <li>Live Data blog_slug_uppercase: <%= @beacon_live_data.blog_slug_uppercase %></li>
        </ul>
      </main>
      """
    })
    
    Pages.create_page_event!(%{
      page_id: page_id,
      event_name: "hello",
      code: """
        {:noreply, Phoenix.LiveView.assign(socket, :message, "Hello \#{event_params["greeting"]["name"]}!")}
      """
    })
    ```

17. Run `ecto.reset` to create and seed our database(s).
    1. `cd apps/beacon_sample`.
    2. `mix ecto.setup` (as our repos haven't been created yet).
    3. `mix ecto.reset` thereafter.
18. We can skip to Step 22 now that the `SafeCode` package works as expected.
19. This is typically where we run into issues with `safe_code` on the inner content of the layout seed, specifically:

    ```elixir
    ** (RuntimeError) invalid_node:
    
    assigns . :inner_content
    ```

    1. If you remove the line `<%= @inner_content %>`, seeding seems to complete.
    2. Running `mix phx.server` throws another error:

        ```elixir
        ** (RuntimeError) invalid_node:

        assigns . :val
        ```

    3. It looks like `safe_code` is problematic and needs to be surgically removed from Beacon for now.
20. In Beacon's repository, remove `SafeCode.Validator.validate_heex!` function calls from the loaders
    1. `lib/beacon/loader/layout_module_loader.ex`
    2. `lib/beacon/loader/page_module_loader.ex`
    3. `lib/beacon/loader/component_module_loader.ex`
21. Fix the seeder to work without SafeCode.
    1. Change line 49 in `apps/beacon_sample/priv/repo/seeds.exs` under `Pages.create_page!` from `<%= for val <- live_data[:vals] do %>` to `<%= for val <- live_data.vals do %>`.
22. Commit the seeder changes.
    1. `Add component seeds`
23. Enable Page Management and the Page Management API in router (`apps/beacon_sample_web/lib/beacon_sample_web/router.ex`).

    ```elixir
    require BeaconWeb.PageManagement
    require BeaconWeb.PageManagementApi

    scope "/page_management", BeaconWeb.PageManagement do
        pipe_through :browser

        BeaconWeb.PageManagement.routes()
    end

    scope "/page_management_api", BeaconWeb.PageManagementApi do
        pipe_through :api

        BeaconWeb.PageManagementApi.routes()
    end
    ```

24. Commit the Page Management router changes.
    1. `Add Page Management routes`
25. Navigate to [http://localhost:4000/beacon/home](http://localhost:4000/beacon/home) to view the main CMS page.
    1. You should see `Header`, `Some Values`, and `Page Footer` with a zoom-in cursor over the page.
26. Navigate to [http://localhost:4000/beacon/blog/beacon_is_awesome](http://localhost:4000/beacon/blog/beacon_is_awesome) to view the blog post.
    1. You should see `Header`, `A blog`, and `Page Footer` with a zoom-in cursor over the page.
27. Navigate to [http://localhost:4000/page_management/pages](http://localhost:4000/page_management/pages) to view the `Page Management` section.
    1. You should see `Listing Pages`, `Reload Modules`, a list of pages, and `New Page`.

### Playground

We should put the page management through its paces to determine points that can be improved.

1. Add another more robust layout.
    1. Can we bring in JS frameworks like Vue? My guess is no, the layout looks to start under a `<main>`.
    2. Inject javascript at the bottom, this should load at the bottom of our `<body>` section.
    3. Try CDN urls first, then localhost.
2. Add another stylesheet. How do we use `stylesheet_urls`?
3. Add another more robust component.
    1. Can we use LiveView slots here? We're on `0.17.7`.
4. A replica of Laravel Nova panel of pages. Welcome and Home are Laravel defaults. Users would be useful as we could integrate with `phx gen auth`.
    1. What migrations are possibly included by Phoenix? Only users?
    2. Add a user profile page.

## Notes

* The dependency `safe_code` was a problem during my first two attempts.
    * The third attempt on 11/6/2022 has no issues so far.
* I ran into issues by failing to add a `BeaconWeb` scope and adding it as `BeaconSampleWeb` instead.
    * Navigating to [http://localhost:4000/page/home](http://localhost:4000/page/home) throws an `UndefinedFunctionError` as `function BeaconSampleWeb.PageLive.__live__/0 is undefined (module BeaconSampleWeb.PageLive is not available)`.
* The sample isn't as "pristine" as I'd like due to the bug fix but it really shouldn't be a showstopper.
    * Fixed this as I generated a new repository. There really aren't a ton of steps.
* As of 3/16 page management only covers the page. The layout, component, and stylesheet models are not covered yet.
* Stylesheets are injected into the `<head>` as inline `<style>` tags.
* Layout sits under `<body><div data-phx-main="true">`
* Running the server (`mix phx.server`) immediately boots our Beacon components before it shows the url.
