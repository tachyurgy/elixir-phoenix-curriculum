# ============================================================================
# Lesson 18: Email Templates - HEEx Templates for Beautiful Emails
# ============================================================================
#
# Building professional, maintainable emails requires proper templating.
# This lesson covers email layouts, HEEx templates, components, and
# best practices for creating emails that look great across clients.
#
# In this lesson, you'll learn:
# - Creating email layouts for consistent branding
# - Writing HEEx templates for emails
# - Building reusable email components
# - Handling dynamic content and assigns
# - Email CSS and styling considerations
#
# Prerequisites:
# - Lesson 17: Swoosh Setup
# - Understanding of Phoenix templates and HEEx
# - Basic HTML/CSS knowledge

# ============================================================================
# Section 1: Email Template Architecture
# ============================================================================

defmodule EmailArchitecture do
  @moduledoc """
  Email templates in Phoenix follow a similar pattern to web templates:

  Structure:
  ```
  lib/
  └── my_app/
      └── emails/
          ├── user_email.ex       # Email building functions
          └── components/
              └── email_components.ex  # Reusable components

  lib/
  └── my_app_web/
      └── templates/
          └── email/
              ├── layouts/
              │   ├── email.html.heex    # HTML layout
              │   └── email.text.heex    # Plain text layout
              └── user/
                  ├── welcome.html.heex  # HTML template
                  └── welcome.text.heex  # Plain text template
  ```

  The separation between emails/ (composition) and templates/ (presentation)
  keeps concerns clean and follows Phoenix conventions.
  """
end

# ============================================================================
# Section 2: Setting Up the Email View
# ============================================================================

defmodule MyAppWeb.EmailView do
  @moduledoc """
  The email view module renders email templates.
  This is the bridge between your email data and templates.
  """

  use MyAppWeb, :view

  # Alternatively, define explicitly:
  # use Phoenix.View, root: "lib/my_app_web/templates"

  # Helper functions available in all email templates
  def format_date(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y")
  end

  def format_currency(amount) do
    "$#{:erlang.float_to_binary(amount / 1, decimals: 2)}"
  end

  def full_name(user) do
    "#{user.first_name} #{user.last_name}"
  end
end

# Modern Phoenix 1.7+ approach using components
defmodule MyAppWeb.EmailHTML do
  @moduledoc """
  Phoenix 1.7+ uses function components for rendering.
  This module handles email template rendering.
  """

  use MyAppWeb, :html

  # Embed templates from the email directory
  embed_templates "email/*"
  embed_templates "email/layouts/*"

  # Or be more specific:
  # embed_templates "email/user/*"

  # Helper functions
  def format_date(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y")
  end

  def app_url(path \\ "/") do
    MyAppWeb.Endpoint.url() <> path
  end
end

# ============================================================================
# Section 3: Email Layouts
# ============================================================================

defmodule EmailLayouts do
  @moduledoc """
  Email layouts provide consistent branding across all emails.
  Always create both HTML and plain text layouts.
  """

  # HTML Layout: lib/my_app_web/templates/email/layouts/email.html.heex
  def html_layout do
    ~S"""
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title><%= @subject %></title>
      <style type="text/css">
        /* Reset styles */
        body {
          margin: 0;
          padding: 0;
          width: 100%;
          background-color: #f4f4f4;
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
          -webkit-font-smoothing: antialiased;
        }

        /* Container */
        .email-container {
          max-width: 600px;
          margin: 0 auto;
          background-color: #ffffff;
        }

        /* Header */
        .email-header {
          background-color: #4f46e5;
          padding: 30px 40px;
          text-align: center;
        }

        .email-header img {
          max-width: 150px;
          height: auto;
        }

        /* Content */
        .email-content {
          padding: 40px;
        }

        /* Footer */
        .email-footer {
          background-color: #f9fafb;
          padding: 30px 40px;
          text-align: center;
          font-size: 12px;
          color: #6b7280;
        }

        /* Typography */
        h1 {
          color: #111827;
          font-size: 24px;
          font-weight: 600;
          margin: 0 0 20px 0;
        }

        p {
          color: #374151;
          font-size: 16px;
          line-height: 1.6;
          margin: 0 0 16px 0;
        }

        /* Buttons */
        .btn {
          display: inline-block;
          padding: 14px 28px;
          background-color: #4f46e5;
          color: #ffffff !important;
          text-decoration: none;
          border-radius: 6px;
          font-weight: 600;
          margin: 20px 0;
        }

        .btn:hover {
          background-color: #4338ca;
        }

        /* Responsive */
        @media only screen and (max-width: 600px) {
          .email-content {
            padding: 20px;
          }
        }
      </style>
    </head>
    <body>
      <center>
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
          <tr>
            <td style="padding: 20px 0;">
              <table class="email-container" role="presentation" cellspacing="0" cellpadding="0" border="0" width="600" align="center">
                <!-- Header -->
                <tr>
                  <td class="email-header">
                    <img src="<%= app_url("/images/logo-white.png") %>" alt="MyApp" />
                  </td>
                </tr>

                <!-- Content -->
                <tr>
                  <td class="email-content">
                    <%= @inner_content %>
                  </td>
                </tr>

                <!-- Footer -->
                <tr>
                  <td class="email-footer">
                    <p>&copy; <%= Date.utc_today().year %> MyApp, Inc. All rights reserved.</p>
                    <p>
                      123 Main Street, Suite 100<br />
                      San Francisco, CA 94102
                    </p>
                    <p style="margin-top: 20px;">
                      <a href="<%= app_url("/unsubscribe?token=#{@unsubscribe_token}") %>" style="color: #6b7280;">
                        Unsubscribe
                      </a>
                      &nbsp;|&nbsp;
                      <a href="<%= app_url("/preferences") %>" style="color: #6b7280;">
                        Email Preferences
                      </a>
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </center>
    </body>
    </html>
    """
  end

  # Plain Text Layout: lib/my_app_web/templates/email/layouts/email.text.heex
  def text_layout do
    ~S"""
    =======================================
    MyApp
    =======================================

    <%= @inner_content %>

    ---

    (c) <%= Date.utc_today().year %> MyApp, Inc.
    123 Main Street, Suite 100
    San Francisco, CA 94102

    Unsubscribe: <%= app_url("/unsubscribe?token=#{@unsubscribe_token}") %>
    """
  end
end

# ============================================================================
# Section 4: Email Templates
# ============================================================================

defmodule EmailTemplates do
  @moduledoc """
  Individual email templates for specific purposes.
  Always create both HTML and plain text versions.
  """

  # Welcome Email HTML: lib/my_app_web/templates/email/user/welcome.html.heex
  def welcome_html do
    ~S"""
    <h1>Welcome to MyApp, <%= @user.first_name %>!</h1>

    <p>
      We're thrilled to have you join our community. Your account has been
      successfully created and you're ready to get started.
    </p>

    <p>Here's what you can do next:</p>

    <ul style="color: #374151; font-size: 16px; line-height: 1.8;">
      <li>Complete your profile</li>
      <li>Connect with other members</li>
      <li>Explore our features</li>
    </ul>

    <center>
      <a href="<%= @getting_started_url %>" class="btn">
        Get Started
      </a>
    </center>

    <p>
      If you have any questions, just reply to this email—we're always
      happy to help!
    </p>

    <p>
      Best,<br />
      The MyApp Team
    </p>
    """
  end

  # Welcome Email Plain Text: lib/my_app_web/templates/email/user/welcome.text.heex
  def welcome_text do
    ~S"""
    Welcome to MyApp, <%= @user.first_name %>!

    We're thrilled to have you join our community. Your account has been
    successfully created and you're ready to get started.

    Here's what you can do next:

    * Complete your profile
    * Connect with other members
    * Explore our features

    Get Started: <%= @getting_started_url %>

    If you have any questions, just reply to this email—we're always
    happy to help!

    Best,
    The MyApp Team
    """
  end

  # Password Reset HTML
  def password_reset_html do
    ~S"""
    <h1>Reset Your Password</h1>

    <p>Hi <%= @user.first_name %>,</p>

    <p>
      We received a request to reset your password. Click the button below
      to create a new password:
    </p>

    <center>
      <a href="<%= @reset_url %>" class="btn">
        Reset Password
      </a>
    </center>

    <p style="color: #6b7280; font-size: 14px;">
      This link will expire in <%= @expiration_hours %> hours.
    </p>

    <p>
      If you didn't request a password reset, you can safely ignore this email.
      Your password will remain unchanged.
    </p>

    <p style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #e5e7eb; color: #6b7280; font-size: 14px;">
      Can't click the button? Copy and paste this URL into your browser:<br />
      <a href="<%= @reset_url %>" style="color: #4f46e5; word-break: break-all;">
        <%= @reset_url %>
      </a>
    </p>
    """
  end

  # Order Confirmation HTML
  def order_confirmation_html do
    ~S"""
    <h1>Order Confirmed!</h1>

    <p>Hi <%= @user.first_name %>,</p>

    <p>
      Thank you for your order. We've received it and will begin processing
      it shortly.
    </p>

    <div style="background-color: #f9fafb; padding: 20px; border-radius: 8px; margin: 20px 0;">
      <p style="margin: 0; font-weight: 600;">Order #<%= @order.number %></p>
      <p style="margin: 8px 0 0 0; color: #6b7280;">
        Placed on <%= format_date(@order.inserted_at) %>
      </p>
    </div>

    <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="margin: 20px 0;">
      <tr style="border-bottom: 1px solid #e5e7eb;">
        <th style="text-align: left; padding: 10px 0; color: #6b7280; font-size: 12px; text-transform: uppercase;">Item</th>
        <th style="text-align: center; padding: 10px 0; color: #6b7280; font-size: 12px; text-transform: uppercase;">Qty</th>
        <th style="text-align: right; padding: 10px 0; color: #6b7280; font-size: 12px; text-transform: uppercase;">Price</th>
      </tr>
      <%= for item <- @order.items do %>
        <tr style="border-bottom: 1px solid #e5e7eb;">
          <td style="padding: 15px 0;">
            <strong><%= item.name %></strong>
            <%= if item.variant do %>
              <br /><span style="color: #6b7280; font-size: 14px;"><%= item.variant %></span>
            <% end %>
          </td>
          <td style="text-align: center; padding: 15px 0;"><%= item.quantity %></td>
          <td style="text-align: right; padding: 15px 0;"><%= format_currency(item.price) %></td>
        </tr>
      <% end %>
      <tr>
        <td colspan="2" style="text-align: right; padding: 15px 0; font-weight: 600;">Total</td>
        <td style="text-align: right; padding: 15px 0; font-weight: 600; font-size: 18px;">
          <%= format_currency(@order.total) %>
        </td>
      </tr>
    </table>

    <center>
      <a href="<%= @order_url %>" class="btn">
        View Order Details
      </a>
    </center>
    """
  end
end

# ============================================================================
# Section 5: Reusable Email Components
# ============================================================================

defmodule MyAppWeb.EmailComponents do
  @moduledoc """
  Reusable components for email templates.
  These components encapsulate common patterns.
  """

  use Phoenix.Component

  @doc """
  Renders a primary call-to-action button.
  """
  attr :href, :string, required: true
  attr :class, :string, default: ""
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <table role="presentation" cellspacing="0" cellpadding="0" border="0" align="center" style="margin: 20px 0;">
      <tr>
        <td style="border-radius: 6px; background-color: #4f46e5;">
          <a href={@href} style={"display: inline-block; padding: 14px 28px; color: #ffffff; text-decoration: none; font-weight: 600; #{@class}"}>
            <%= render_slot(@inner_block) %>
          </a>
        </td>
      </tr>
    </table>
    """
  end

  @doc """
  Renders a secondary/outline button.
  """
  attr :href, :string, required: true
  slot :inner_block, required: true

  def button_secondary(assigns) do
    ~H"""
    <table role="presentation" cellspacing="0" cellpadding="0" border="0" align="center" style="margin: 20px 0;">
      <tr>
        <td style="border-radius: 6px; border: 2px solid #4f46e5;">
          <a href={@href} style="display: inline-block; padding: 12px 26px; color: #4f46e5; text-decoration: none; font-weight: 600;">
            <%= render_slot(@inner_block) %>
          </a>
        </td>
      </tr>
    </table>
    """
  end

  @doc """
  Renders an info box/callout.
  """
  attr :type, :atom, default: :info, values: [:info, :warning, :success, :error]
  slot :inner_block, required: true

  def callout(assigns) do
    colors = %{
      info: %{bg: "#eff6ff", border: "#3b82f6", text: "#1e40af"},
      warning: %{bg: "#fffbeb", border: "#f59e0b", text: "#92400e"},
      success: %{bg: "#ecfdf5", border: "#10b981", text: "#065f46"},
      error: %{bg: "#fef2f2", border: "#ef4444", text: "#991b1b"}
    }

    assigns = assign(assigns, :colors, colors[assigns.type])

    ~H"""
    <div style={"background-color: #{@colors.bg}; border-left: 4px solid #{@colors.border}; padding: 16px; margin: 20px 0; border-radius: 0 6px 6px 0;"}>
      <p style={"color: #{@colors.text}; margin: 0; font-size: 14px;"}>
        <%= render_slot(@inner_block) %>
      </p>
    </div>
    """
  end

  @doc """
  Renders a divider/separator.
  """
  attr :spacing, :integer, default: 30

  def divider(assigns) do
    ~H"""
    <hr style={"border: none; border-top: 1px solid #e5e7eb; margin: #{@spacing}px 0;"} />
    """
  end

  @doc """
  Renders a two-column layout.
  """
  slot :left, required: true
  slot :right, required: true

  def two_column(assigns) do
    ~H"""
    <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
      <tr>
        <td width="48%" valign="top" style="padding-right: 10px;">
          <%= render_slot(@left) %>
        </td>
        <td width="4%"></td>
        <td width="48%" valign="top" style="padding-left: 10px;">
          <%= render_slot(@right) %>
        </td>
      </tr>
    </table>
    """
  end

  @doc """
  Renders a user avatar.
  """
  attr :user, :map, required: true
  attr :size, :integer, default: 50

  def avatar(assigns) do
    initials = String.first(assigns.user.first_name) <> String.first(assigns.user.last_name)
    assigns = assign(assigns, :initials, initials)

    ~H"""
    <table role="presentation" cellspacing="0" cellpadding="0" border="0">
      <tr>
        <td style={"width: #{@size}px; height: #{@size}px; border-radius: 50%; background-color: #4f46e5; text-align: center; vertical-align: middle;"}>
          <span style={"color: #ffffff; font-weight: 600; font-size: #{@size * 0.4}px;"}>
            <%= @initials %>
          </span>
        </td>
      </tr>
    </table>
    """
  end

  @doc """
  Renders social media links.
  """
  attr :twitter, :string, default: nil
  attr :facebook, :string, default: nil
  attr :linkedin, :string, default: nil
  attr :instagram, :string, default: nil

  def social_links(assigns) do
    ~H"""
    <table role="presentation" cellspacing="0" cellpadding="0" border="0" align="center">
      <tr>
        <%= if @twitter do %>
          <td style="padding: 0 8px;">
            <a href={"https://twitter.com/#{@twitter}"}>
              <img src={app_url("/images/email/twitter.png")} alt="Twitter" width="24" height="24" />
            </a>
          </td>
        <% end %>
        <%= if @facebook do %>
          <td style="padding: 0 8px;">
            <a href={"https://facebook.com/#{@facebook}"}>
              <img src={app_url("/images/email/facebook.png")} alt="Facebook" width="24" height="24" />
            </a>
          </td>
        <% end %>
        <%= if @linkedin do %>
          <td style="padding: 0 8px;">
            <a href={"https://linkedin.com/company/#{@linkedin}"}>
              <img src={app_url("/images/email/linkedin.png")} alt="LinkedIn" width="24" height="24" />
            </a>
          </td>
        <% end %>
        <%= if @instagram do %>
          <td style="padding: 0 8px;">
            <a href={"https://instagram.com/#{@instagram}"}>
              <img src={app_url("/images/email/instagram.png")} alt="Instagram" width="24" height="24" />
            </a>
          </td>
        <% end %>
      </tr>
    </table>
    """
  end

  defp app_url(path), do: MyAppWeb.Endpoint.url() <> path
end

# ============================================================================
# Section 6: Building Emails with Templates
# ============================================================================

defmodule MyApp.UserEmail do
  @moduledoc """
  Email composition module that uses templates for rendering.
  """

  import Swoosh.Email
  alias MyAppWeb.EmailHTML

  @from {"MyApp", "noreply@myapp.com"}

  def welcome(user) do
    new()
    |> from(@from)
    |> to({full_name(user), user.email})
    |> subject("Welcome to MyApp!")
    |> render_email(:welcome,
      user: user,
      getting_started_url: url("/getting-started"),
      unsubscribe_token: generate_token(user)
    )
  end

  def password_reset(user, token) do
    new()
    |> from(@from)
    |> to({full_name(user), user.email})
    |> subject("Reset Your Password")
    |> render_email(:password_reset,
      user: user,
      reset_url: url("/reset-password?token=#{token}"),
      expiration_hours: 24,
      unsubscribe_token: generate_token(user)
    )
  end

  def order_confirmation(user, order) do
    new()
    |> from(@from)
    |> to({full_name(user), user.email})
    |> subject("Order Confirmed - ##{order.number}")
    |> render_email(:order_confirmation,
      user: user,
      order: order,
      order_url: url("/orders/#{order.id}"),
      unsubscribe_token: generate_token(user)
    )
  end

  # Private helpers

  defp render_email(email, template, assigns) do
    assigns = Map.new(assigns)

    email
    |> html_body(render_html(template, assigns))
    |> text_body(render_text(template, assigns))
  end

  defp render_html(template, assigns) do
    # Render the template
    inner_content = EmailHTML.render("user/#{template}.html", assigns)

    # Wrap in layout
    EmailHTML.render("layouts/email.html", Map.put(assigns, :inner_content, inner_content))
  end

  defp render_text(template, assigns) do
    inner_content = EmailHTML.render("user/#{template}.text", assigns)
    EmailHTML.render("layouts/email.text", Map.put(assigns, :inner_content, inner_content))
  end

  defp full_name(user), do: "#{user.first_name} #{user.last_name}"
  defp url(path), do: MyAppWeb.Endpoint.url() <> path
  defp generate_token(user), do: Phoenix.Token.sign(MyAppWeb.Endpoint, "unsubscribe", user.id)
end

# ============================================================================
# Section 7: Phoenix 1.7+ Approach with Verified Routes
# ============================================================================

defmodule MyApp.ModernUserEmail do
  @moduledoc """
  Modern approach using Phoenix 1.7+ features including verified routes.
  """

  import Swoosh.Email
  use MyAppWeb, :verified_routes

  @from {"MyApp", "noreply@myapp.com"}

  def welcome(user) do
    new()
    |> from(@from)
    |> to({user.name, user.email})
    |> subject("Welcome to MyApp!")
    |> assign(:user, user)
    |> assign(:url, url(~p"/getting-started"))
    |> render_body()
  end

  defp render_body(email) do
    heex_template = """
    <h1>Welcome, <%= @user.name %>!</h1>
    <p>Get started at: <a href="<%= @url %>"><%= @url %></a></p>
    """

    # In practice, you'd use Phoenix.Template.render_to_string/4
    email
    |> html_body(EEx.eval_string(heex_template, assigns: email.assigns))
    |> text_body("Welcome, #{email.assigns.user.name}!\n\nGet started at: #{email.assigns.url}")
  end
end

# ============================================================================
# Section 8: Email CSS Best Practices
# ============================================================================

defmodule EmailCSSGuide do
  @moduledoc """
  Email CSS has unique constraints due to varying client support.
  Follow these guidelines for maximum compatibility.
  """

  def css_guidelines do
    """
    EMAIL CSS BEST PRACTICES
    ========================

    1. USE INLINE STYLES
       - Many email clients strip <style> tags
       - Always inline critical styles
       - Use tools like Juice or Premailer for inlining

    2. TABLE-BASED LAYOUTS
       - Flexbox and Grid have poor support
       - Use nested tables for layouts
       - Always use role="presentation" for layout tables

    3. SUPPORTED PROPERTIES
       Safe to use:
       - background-color
       - border, border-radius (varies)
       - color
       - font-family, font-size, font-weight
       - line-height
       - margin, padding
       - text-align, text-decoration
       - width, max-width, height

       Avoid:
       - position: absolute/fixed
       - float (limited support)
       - flexbox, grid
       - calc()
       - CSS variables
       - ::before, ::after pseudo-elements

    4. IMAGES
       - Always include alt text
       - Specify width and height
       - Use absolute URLs
       - Consider images may be blocked by default

    5. FONTS
       - Stick to web-safe fonts
       - Use font stacks with fallbacks
       - Web fonts have limited support

    6. RESPONSIVE DESIGN
       - Use max-width for containers
       - Media queries work in some clients
       - Design mobile-first where possible

    7. DARK MODE
       - Test in dark mode (Gmail, Apple Mail)
       - Use transparent backgrounds where possible
       - Provide dark-mode-specific styles via media query
    """
  end

  def dark_mode_support do
    """
    /* Dark mode support for email */
    @media (prefers-color-scheme: dark) {
      .email-container {
        background-color: #1f2937 !important;
      }

      h1, p {
        color: #f9fafb !important;
      }

      .email-footer {
        background-color: #111827 !important;
      }
    }

    /* Outlook dark mode */
    [data-ogsc] .email-container {
      background-color: #1f2937 !important;
    }
    """
  end
end

# ============================================================================
# Section 9: Multipart Emails
# ============================================================================

defmodule MultipartEmails do
  @moduledoc """
  Always send both HTML and plain text versions.
  This ensures compatibility and improves deliverability.
  """

  import Swoosh.Email

  def build_multipart_email(user, template_name) do
    assigns = %{user: user, app_name: "MyApp"}

    new()
    |> from({"MyApp", "noreply@myapp.com"})
    |> to({user.name, user.email})
    |> subject(subject_for(template_name))
    |> html_body(render_html_template(template_name, assigns))
    |> text_body(render_text_template(template_name, assigns))
  end

  defp subject_for(:welcome), do: "Welcome!"
  defp subject_for(:password_reset), do: "Reset Your Password"
  defp subject_for(_), do: "Notification from MyApp"

  defp render_html_template(template, assigns) do
    # Use EEx or HEEx template rendering
    template_path = "lib/my_app_web/templates/email/#{template}.html.heex"

    EEx.eval_file(template_path, assigns: assigns)
  end

  defp render_text_template(template, assigns) do
    template_path = "lib/my_app_web/templates/email/#{template}.text.heex"

    EEx.eval_file(template_path, assigns: assigns)
  end

  # Converting HTML to plain text automatically
  def html_to_text(html) do
    html
    |> String.replace(~r/<br\s*\/?>/, "\n")
    |> String.replace(~r/<\/p>/, "\n\n")
    |> String.replace(~r/<li>/, "* ")
    |> String.replace(~r/<\/li>/, "\n")
    |> String.replace(~r/<a[^>]*href="([^"]*)"[^>]*>([^<]*)<\/a>/, "\\2 (\\1)")
    |> String.replace(~r/<[^>]+>/, "")
    |> String.replace(~r/&nbsp;/, " ")
    |> String.replace(~r/&amp;/, "&")
    |> String.replace(~r/&lt;/, "<")
    |> String.replace(~r/&gt;/, ">")
    |> String.replace(~r/\n{3,}/, "\n\n")
    |> String.trim()
  end
end

# ============================================================================
# Section 10: Dynamic Content and Personalization
# ============================================================================

defmodule DynamicEmails do
  @moduledoc """
  Techniques for personalizing emails with dynamic content.
  """

  import Swoosh.Email

  def personalized_newsletter(user, articles) do
    # Filter articles based on user preferences
    relevant_articles =
      articles
      |> Enum.filter(&matches_interests?(&1, user.interests))
      |> Enum.take(5)

    new()
    |> from({"MyApp Weekly", "newsletter@myapp.com"})
    |> to({user.name, user.email})
    |> subject(personalized_subject(user))
    |> assign(:user, user)
    |> assign(:articles, relevant_articles)
    |> assign(:greeting, time_based_greeting())
    |> render_newsletter()
  end

  defp matches_interests?(article, interests) do
    article.tags
    |> MapSet.new()
    |> MapSet.intersection(MapSet.new(interests))
    |> MapSet.size()
    |> Kernel.>(0)
  end

  defp personalized_subject(user) do
    variations = [
      "#{user.first_name}, here's what's new this week",
      "Your weekly digest is ready, #{user.first_name}",
      "#{user.first_name}'s personalized reading list"
    ]

    # Deterministic selection based on user ID
    Enum.at(variations, rem(user.id, length(variations)))
  end

  defp time_based_greeting do
    hour = DateTime.utc_now().hour

    cond do
      hour < 12 -> "Good morning"
      hour < 17 -> "Good afternoon"
      true -> "Good evening"
    end
  end

  defp render_newsletter(email) do
    html = """
    <h1><%= @greeting %>, <%= @user.first_name %>!</h1>

    <p>Here are this week's top articles picked just for you:</p>

    <%= for article <- @articles do %>
      <div style="margin-bottom: 20px; padding: 15px; border: 1px solid #e5e7eb; border-radius: 8px;">
        <h3 style="margin: 0 0 10px 0;">
          <a href="<%= article.url %>" style="color: #4f46e5; text-decoration: none;">
            <%= article.title %>
          </a>
        </h3>
        <p style="color: #6b7280; font-size: 14px; margin: 0;">
          <%= article.excerpt %>
        </p>
      </div>
    <% end %>
    """

    email
    |> html_body(EEx.eval_string(html, assigns: email.assigns))
    |> text_body(render_text_newsletter(email.assigns))
  end

  defp render_text_newsletter(assigns) do
    """
    #{assigns.greeting}, #{assigns.user.first_name}!

    Here are this week's top articles picked just for you:

    #{Enum.map_join(assigns.articles, "\n\n", fn article ->
      "* #{article.title}\n  #{article.url}\n  #{article.excerpt}"
    end)}
    """
  end
end

# ============================================================================
# Section 11: Exercises
# ============================================================================

defmodule Exercises do
  @moduledoc """
  Practice exercises for email templates.
  """

  # Exercise 1: Create a Welcome Email Suite
  # Build a complete welcome email with:
  # - HTML and plain text versions
  # - A header with logo
  # - Welcome message with user's name
  # - Three feature highlights
  # - Call-to-action button
  # - Social media links in footer

  # Exercise 2: Order Status Email
  # Create an order status notification email that:
  # - Shows order number and status
  # - Displays shipping address
  # - Lists ordered items with prices
  # - Shows tracking information when available
  # - Includes estimated delivery date

  # Exercise 3: Email Component Library
  # Build a set of reusable components:
  # - Alert boxes (info, warning, error, success)
  # - Feature cards with icons
  # - Testimonial/quote blocks
  # - Progress indicators
  # - Pricing tables

  # Exercise 4: Responsive Email Layout
  # Create a responsive email that:
  # - Has a two-column layout on desktop
  # - Stacks to single column on mobile
  # - Images scale appropriately
  # - Buttons are tap-friendly on mobile

  # Exercise 5: Dark Mode Support
  # Add dark mode support to an existing email:
  # - Detect user preference
  # - Provide alternative colors
  # - Ensure images work on both light/dark backgrounds
  # - Test in multiple email clients
end

# ============================================================================
# Section 12: Solutions
# ============================================================================

defmodule Solutions do
  import Swoosh.Email

  # Solution 1: Welcome Email Suite
  defmodule WelcomeEmail do
    def build(user) do
      Swoosh.Email.new()
      |> from({"MyApp", "welcome@myapp.com"})
      |> to({user.name, user.email})
      |> subject("Welcome to MyApp, #{user.first_name}!")
      |> html_body(html_content(user))
      |> text_body(text_content(user))
    end

    defp html_content(user) do
      """
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; margin: 0; padding: 0; }
          .container { max-width: 600px; margin: 0 auto; }
          .header { background: #4f46e5; padding: 30px; text-align: center; }
          .content { padding: 40px; }
          .feature { padding: 15px; margin: 10px 0; background: #f9fafb; border-radius: 8px; }
          .btn { display: inline-block; padding: 14px 28px; background: #4f46e5; color: white; text-decoration: none; border-radius: 6px; }
          .footer { padding: 30px; text-align: center; background: #f3f4f6; }
          .social a { margin: 0 10px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <img src="https://myapp.com/logo-white.png" alt="MyApp" width="120" />
          </div>
          <div class="content">
            <h1>Welcome, #{user.first_name}!</h1>
            <p>We're excited to have you join MyApp. Here's what you can do:</p>

            <div class="feature">
              <strong>Create Projects</strong>
              <p>Organize your work into projects for easy management.</p>
            </div>
            <div class="feature">
              <strong>Collaborate</strong>
              <p>Invite team members and work together in real-time.</p>
            </div>
            <div class="feature">
              <strong>Track Progress</strong>
              <p>Monitor your progress with powerful analytics.</p>
            </div>

            <p style="text-align: center; margin: 30px 0;">
              <a href="https://myapp.com/getting-started" class="btn">Get Started</a>
            </p>
          </div>
          <div class="footer">
            <div class="social">
              <a href="https://twitter.com/myapp"><img src="https://myapp.com/twitter.png" width="24" /></a>
              <a href="https://facebook.com/myapp"><img src="https://myapp.com/facebook.png" width="24" /></a>
              <a href="https://linkedin.com/company/myapp"><img src="https://myapp.com/linkedin.png" width="24" /></a>
            </div>
            <p style="color: #6b7280; font-size: 12px; margin-top: 20px;">
              &copy; #{Date.utc_today().year} MyApp, Inc.
            </p>
          </div>
        </div>
      </body>
      </html>
      """
    end

    defp text_content(user) do
      """
      Welcome to MyApp, #{user.first_name}!

      We're excited to have you join MyApp. Here's what you can do:

      * CREATE PROJECTS
        Organize your work into projects for easy management.

      * COLLABORATE
        Invite team members and work together in real-time.

      * TRACK PROGRESS
        Monitor your progress with powerful analytics.

      Get Started: https://myapp.com/getting-started

      ---

      Follow us:
      Twitter: https://twitter.com/myapp
      Facebook: https://facebook.com/myapp
      LinkedIn: https://linkedin.com/company/myapp

      (c) #{Date.utc_today().year} MyApp, Inc.
      """
    end
  end

  # Solution 3: Email Component Module
  defmodule EmailComponents do
    def alert(type, message) do
      colors = %{
        info: {"#eff6ff", "#3b82f6", "#1e40af"},
        warning: {"#fffbeb", "#f59e0b", "#92400e"},
        error: {"#fef2f2", "#ef4444", "#991b1b"},
        success: {"#ecfdf5", "#10b981", "#065f46"}
      }

      {bg, border, text} = colors[type]

      """
      <div style="background: #{bg}; border-left: 4px solid #{border}; padding: 16px; margin: 20px 0;">
        <p style="color: #{text}; margin: 0;">#{message}</p>
      </div>
      """
    end

    def feature_card(icon_url, title, description) do
      """
      <div style="padding: 20px; border: 1px solid #e5e7eb; border-radius: 8px; margin: 10px 0;">
        <img src="#{icon_url}" width="40" height="40" style="margin-bottom: 10px;" />
        <h3 style="margin: 0 0 10px 0; color: #111827;">#{title}</h3>
        <p style="margin: 0; color: #6b7280; font-size: 14px;">#{description}</p>
      </div>
      """
    end

    def quote_block(quote, author, title \\ nil) do
      author_line = if title, do: "#{author}, #{title}", else: author

      """
      <div style="border-left: 4px solid #4f46e5; padding: 20px; margin: 20px 0; background: #f9fafb;">
        <p style="font-size: 18px; font-style: italic; color: #374151; margin: 0 0 15px 0;">
          "#{quote}"
        </p>
        <p style="font-size: 14px; color: #6b7280; margin: 0;">
          — #{author_line}
        </p>
      </div>
      """
    end

    def progress_bar(percentage, label \\ nil) do
      """
      <div style="margin: 20px 0;">
        #{if label, do: "<p style=\"margin: 0 0 8px 0; font-size: 14px; color: #374151;\">#{label}</p>", else: ""}
        <div style="background: #e5e7eb; border-radius: 9999px; height: 8px; overflow: hidden;">
          <div style="background: #4f46e5; height: 100%; width: #{percentage}%; border-radius: 9999px;"></div>
        </div>
        <p style="margin: 8px 0 0 0; font-size: 12px; color: #6b7280; text-align: right;">#{percentage}%</p>
      </div>
      """
    end
  end
end

# ============================================================================
# Summary
# ============================================================================

defmodule Summary do
  @moduledoc """
  Key takeaways from this lesson:

  1. TEMPLATE STRUCTURE
     - Separate composition (emails/) from presentation (templates/)
     - Always create both HTML and plain text versions
     - Use layouts for consistent branding

  2. HTML EMAIL CONSTRAINTS
     - Use table-based layouts
     - Inline critical styles
     - Test across email clients
     - Support dark mode where possible

  3. COMPONENTS
     - Build reusable email components
     - Use Phoenix function components
     - Keep components email-client compatible

  4. PERSONALIZATION
     - Use assigns for dynamic content
     - Personalize subject lines
     - Filter content based on user preferences

  5. BEST PRACTICES
     - Always provide plain text alternatives
     - Test in multiple email clients
     - Use absolute URLs for all links and images
     - Include unsubscribe links

  Next lesson: Email Delivery - Sending emails with different strategies
  """
end
