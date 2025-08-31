#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif
#include <gtk/gtk.h>
#include <glib.h>

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Show the window after the first Flutter frame (avoids flashes on some WMs).
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

static gchar* first_existing_path(const gchar* const* candidates) {
  for (int i = 0; candidates[i] != NULL; ++i) {
    if (g_file_test(candidates[i], G_FILE_TEST_EXISTS)) {
      return g_strdup(candidates[i]);
    }
  }
  return NULL;
}

static gchar* exe_dir_path() {
  // Prefer the real executable location, not the CWD.
  gchar* link = g_file_read_link("/proc/self/exe", NULL);
  if (link) {
    gchar* dir = g_path_get_dirname(link);
    g_free(link);
    return dir;
  }
  // Fallback: current directory
  return g_get_current_dir();
}


// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
    // Make GTK look up our icon from the theme by name
    gtk_window_set_default_icon_name("org.munkulu.asante_typing");
    gtk_window_set_icon_name(window, "org.munkulu.asante_typing");


  // ---- Window/icon setup ----------------------------------------------------
  const char* installed_icon =
      "/usr/share/icons/hicolor/256x256/apps/org.munkulu.asante_typing.png";

  if (g_file_test(installed_icon, G_FILE_TEST_EXISTS)) {
    gtk_window_set_icon_from_file(window, installed_icon, nullptr);
  } else {
    // dev/bundle: <exe_dir>/data/flutter_assets/assets/icon/app_icon.png
    g_autofree gchar* exe_dir = exe_dir_path();
    g_autofree gchar* bundled_icon = g_build_filename(
        exe_dir, "data", "flutter_assets", "assets", "icon", "app_icon.png", NULL);
    if (g_file_test(bundled_icon, G_FILE_TEST_EXISTS)) {
      gtk_window_set_icon_from_file(window, bundled_icon, nullptr);
    }
  }

  // Use a header bar in GNOME (common on Ubuntu).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "asante_typing");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "asante_typing");
  }

  gtk_window_set_default_size(window, 1280, 720);

  // ---- Flutter project & paths ---------------------------------------------
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project,
                                                self->dart_entrypoint_arguments);

  g_autofree gchar* exe_dir = exe_dir_path();

  // Candidates: system first, then next to the executable (bundle)
  g_autofree gchar* bundle_assets = g_build_filename(exe_dir, "data", "flutter_assets", NULL);
  g_autofree gchar* bundle_icu    = g_build_filename(exe_dir, "data", "icudtl.dat", NULL);
  g_autofree gchar* bundle_aot    = g_build_filename(exe_dir, "lib", "libapp.so", NULL);

  const gchar* assets_candidates[] = {
    "/usr/share/asante_typing/flutter_assets",
    bundle_assets,
    NULL
  };
  const gchar* icu_candidates[] = {
    "/usr/share/asante_typing/icudtl.dat",
    bundle_icu,
    NULL
  };
  const gchar* aot_candidates[] = {
    // Ubuntu multi-arch lib dir:
    "/usr/lib/x86_64-linux-gnu/asante_typing/libapp.so",
    // Generic lib dir:
    "/usr/lib/asante_typing/libapp.so",
    // Bundle Release next to exe:
    bundle_aot,
    NULL
  };

  g_autofree gchar* assets_path = first_existing_path(assets_candidates);
  g_autofree gchar* icu_path    = first_existing_path(icu_candidates);
  g_autofree gchar* aot_path    = first_existing_path(aot_candidates);

  if (!assets_path || !icu_path) {
    g_warning("Missing essential runtime files. assets:%s, icu:%s",
              assets_path ? assets_path : "NULL",
              icu_path ? icu_path : "NULL");
  } else {
    fl_dart_project_set_assets_path(project, assets_path);
    fl_dart_project_set_icu_data_path(project, icu_path);
  }

  // Prefer AOT in Release if present; otherwise engine uses kernel_blob.bin
  if (aot_path) {
    fl_dart_project_set_aot_library_path(project, aot_path);
  }

  // ---- Create view & show when first frame arrives -------------------------
  FlView* view = fl_view_new(project);

  // Optional: set background color (#000000 = black; #00000000 transparent)
  GdkRGBA background_color;
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);

  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb), self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));
  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;
  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Helps DEs map the process to the .desktop entry
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
