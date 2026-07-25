## Widget Tree

Below is a high-level widget tree of the app (entry -> major screens).

```mermaid
graph TD
  A[CrmMobileApp]
  A --> B[ClerkAuth]
  B --> C[MaterialApp]
  C --> D[AnnotatedRegion<SystemUiOverlayStyle>]
  C --> E[home: ClerkAuthBuilder]
  E --> F[SignedIn -> RootScreen]
  E --> G[SignedOut -> _SignedOutGateScreen / ClerkAuthenticationScreen]

  F --> H[RootScreen]
  H --> I[Loading: Scaffold > Center > SpinKitFoldingCube]
  H --> J[SeniorCrmHomeScreen]
  H --> K[VisitTeamHomeScreen]
  H --> L[Access Denied: Scaffold > Column > Icon/Text/Button]

  J --> J1[Scaffold]
  J --> J2[AnimatedSwitcher -> Dashboard / Queue / Budget / Profile]
  J --> J3[Bottom NavigationBar]

  K --> K1[Scaffold]
  K --> K2[AnimatedSwitcher -> Dashboard / Visits / TodayVisits / Profile or Control]
  K --> K3[Bottom NavigationBar]

  G --> M[ClerkAuthenticationScreen]
  M --> M1[Scaffold > Stack]
  M --> M2[WaveWidget (background)]
  M --> M3[SafeArea > Center > Column (Welcome, ClerkAuthentication or Loader)]

```

Summary:
- Entry: `CrmMobileApp` wraps `ClerkAuth` and `MaterialApp`.
- Auth flow: `ClerkAuthBuilder` chooses `RootScreen` (signed in) or `ClerkAuthenticationScreen` (signed out).
- `RootScreen` branches to `SeniorCrmHomeScreen`, `VisitTeamHomeScreen` or an Access Denied `Scaffold`.
- Each home screen uses a `Scaffold` with an `AnimatedSwitcher` body and a bottom `NavigationBar`.

You can view the in-app textual widget tree by opening the `WidgetTreeView` widget at [lib/widgets/widget_tree_view.dart](lib/widgets/widget_tree_view.dart#L1).
