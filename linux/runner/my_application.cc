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

static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

static gchar* first_existing(const gchar* const* candidates) {
  for (int i = 0; candidates[i] != NULL; ++i) {
    if (g_file_test(candidates[i], G_FILE_TEST_EXISTS)) return g_strdup(candidates[i]);
  }
  return NULL;
}

static gchar* exe_dir() {
  gchar* link = g_file_read_link("/proc/self/exe", NULL);
  if (link) { gchar* dir = g_path_get_dirname(link); g_free(link); return dir; }
  return g_get_current_dir();
}

static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window = GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
  // Make GTK look up our icon from the theme by name
  gtk_window_set_default_icon_name("org.munkulu.asante_typing");
  gtk_window_set_icon_name(window, "org.munkulu.asante_typing");

  // Icon: prefer system icon; fall back to bundle icon.
  const char* sys_icon = "/usr/share/icons/hicolor/256x256/apps/org.munkulu.asante_typing.png";
  if (g_file_test(sys_icon, G_FILE_TEST_EXISTS)) {
    gtk_window_set_icon_from_file(window, sys_icon, nullptr);
  } else {
    g_autofree gchar* dir = exe_dir();
    g_autofree gchar* icon = g_build_filename(dir, "data", "flutter_assets", "assets", "icon", "app_icon.png", NULL);
    if (g_file_test(icon, G_FILE_TEST_EXISTS)) gtk_window_set_icon_from_file(window, icon, nullptr);
  }

  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm, "GNOME Shell") != 0) use_header_bar = FALSE;
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* hb = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(hb));
    gtk_header_bar_set_title(hb, "asante_typing");
    gtk_header_bar_set_show_close_button(hb, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(hb));
  } else {
    gtk_window_set_title(window, "asante_typing");
  }
  gtk_window_set_default_size(window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  // Build candidate lists (system first, then bundle next to the exe)
  g_autofree gchar* dir = exe_dir();
  g_autofree gchar* b_assets = g_build_filename(dir, "data", "flutter_assets", NULL);
  g_autofree gchar* b_icu    = g_build_filename(dir, "data", "icudtl.dat", NULL);
  g_autofree gchar* b_aot    = g_build_filename(dir, "lib",  "libapp.so", NULL);

  const gchar* assets_cand[] = {
    "/usr/share/asante_typing/flutter_assets", b_assets, NULL
  };
  const gchar* icu_cand[] = {
    "/usr/share/asante_typing/icudtl.dat",     b_icu,    NULL
  };
  const gchar* aot_cand[] = {
    "/usr/lib/x86_64-linux-gnu/asante_typing/libapp.so", // Ubuntu multi-arch
    "/usr/lib/asante_typing/libapp.so",                  // Generic
    b_aot,                                               // Bundle Release
    NULL
  };

  g_autofree gchar* assets = first_existing(assets_cand);
  g_autofree gchar* icu    = first_existing(icu_cand);
  g_autofree gchar* aot    = first_existing(aot_cand);

  if (!assets || !icu) {
    g_warning("Missing runtime files. assets=%s icu=%s",
              assets ? assets : "NULL", icu ? icu : "NULL");
  } else {
    fl_dart_project_set_assets_path(project, assets);
    fl_dart_project_set_icu_data_path(project, icu);
  }
  if (aot) fl_dart_project_set_aot_library_path(project, aot);

  FlView* view = fl_view_new(project);
  GdkRGBA bg; gdk_rgba_parse(&bg, "#000000"); fl_view_set_background_color(view, &bg);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb), self);
  gtk_widget_realize(GTK_WIDGET(view));
  fl_register_plugins(FL_PLUGIN_REGISTRY(view));
  gtk_widget_grab_focus(GTK_WIDGET(view));
}

static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);
  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1; return TRUE;
  }
  g_application_activate(application);
  *exit_status = 0; return TRUE;
}

static void my_application_startup(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}
static void my_application_shutdown(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}
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
  g_set_prgname(APPLICATION_ID);
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
