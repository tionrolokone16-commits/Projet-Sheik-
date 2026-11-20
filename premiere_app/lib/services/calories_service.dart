import '../models/jour_habitudes.dart';
import '../models/plat.dart';
import '../models/recette.dart';
import '../models/repas_photo.dart';

/// Estimation des calories des repas.
///
/// Ce sont des ESTIMATIONS pour une portion moyenne faite maison : chaque
/// repas peut être corrigé à la main. Les valeurs viennent de compositions
/// courantes (féculent, sauce, huile, protéine) et restent approximatives.
class CaloriesService {
  CaloriesService._();

  /// Multiplicateur selon la taille de la portion.
  static double multiplicateur(TaillePortion t) => switch (t) {
    TaillePortion.petite => 0.75,
    TaillePortion.moyenne => 1.0,
    TaillePortion.grande => 1.3,
  };

  /// Calories estimées d'une portion moyenne, par plat du catalogue.
  static const kcalParPlat = <String, int>{
    // Côte d'Ivoire
    'ci_attieke_poisson': 650,
    'ci_garba': 750,
    'ci_alloco': 450,
    'ci_foutou_graine': 800,
    'ci_foutou_claire': 650,
    'ci_kedjenou': 550,
    'ci_riz_arachide': 750,
    'ci_riz_aubergine': 600,
    'ci_placali_gombo': 600,
    'ci_cabato_feuille': 550,
    'ci_riz_gras': 700,
    'ci_igname_legume': 450,
    'ci_banane_braisee': 500,
    'ci_claclo': 250,
    'ci_degue': 300,
    'ci_gnamakoudji': 120,
    'ci_bissap': 120,
    'ci_bouillie_mil': 250,
    // Sénégal
    'sn_thieb': 750,
    'sn_yassa': 650,
    'sn_mafe': 750,
    'sn_soupou_kandja': 650,
    'sn_thiakry': 300,
    'sn_pastels': 300,
    // Cameroun
    'cm_ndole': 700,
    'cm_eru': 650,
    'cm_poulet_dg': 750,
    'cm_koki': 400,
    'cm_mbongo': 550,
    'cm_beignets_haricots': 450,
    // Ghana
    'gh_jollof': 650,
    'gh_waakye': 650,
    'gh_banku': 650,
    'gh_fufu_light': 600,
    'gh_red_red': 650,
    'gh_kelewele': 350,
    // Nigeria
    'ng_egusi': 850,
    'ng_efo_riro': 450,
    'ng_moi_moi': 300,
    'ng_pepper_soup': 300,
    'ng_suya': 350,
    'ng_akara': 350,
    // Mali
    'ml_to_gombo': 500,
    'ml_fonio': 500,
    'ml_tiga': 700,
    // Bénin et Togo
    'bj_amiwo': 650,
    'bj_gboman': 550,
    'bj_ablo': 500,
    // Basiques
    'b_biscottes_yaourt': 150,
    'b_fruit': 80,
    'b_yaourt': 70,
    'b_pain': 250,
    'b_the': 20,
    'b_crudites': 80,
    'b_salade_poulet': 350,
    'b_poisson_braise': 300,
    'b_poulet_braise': 400,
    'b_brochette': 250,
    'b_haricot_vert': 350,
    'b_petit_pois': 400,
    'b_carotte': 300,
    'b_soupe': 120,
    'b_spaghetti': 650,
    'b_riz_blanc': 550,
    'b_eau': 0,
    'b_jus': 120,
    'b_soda': 140,
    'b_gateau': 350,
  };

  /// Estimation par catégorie (plats personnels sans valeur connue).
  static int parCategorie(CategoriePlat c) => switch (c) {
    CategoriePlat.petitDejeuner => 300,
    CategoriePlat.plat => 600,
    CategoriePlat.simple => 350,
    CategoriePlat.enCas => 200,
    CategoriePlat.dessert => 300,
    CategoriePlat.boisson => 120,
  };

  /// Calories d'une portion moyenne d'un plat.
  static int kcalPlat(Plat p) => kcalParPlat[p.id] ?? parCategorie(p.categorie);

  /// Estimation à partir de l'assiette et du moment (repas en photo, menu du plan) :
  /// plus il y a de féculents, plus l'assiette est riche.
  static int parAssiette(Repas moment, Portions portions) {
    final base = switch (moment) {
      Repas.petitDejeuner => 350,
      Repas.dejeuner => 600,
      Repas.diner => 550,
      Repas.collation => 200,
    };
    final feculents = portions.total > 0 ? portions.feculents : 0.25;
    return (base * (0.8 + 0.8 * feculents)).round();
  }

  /// Calories estimées d'un repas noté (taille de portion comprise),
  /// sauf si une valeur a été saisie à la main.
  /// [plats] : catalogue et plats personnels, pour retrouver le plat par son nom.
  static int kcalRepas(RepasPhoto r, Iterable<Plat> plats) {
    if (r.kcalManuel != null) return r.kcalManuel!;
    final nom = r.nomPlat?.trim().toLowerCase();
    Plat? plat;
    if (nom != null) {
      for (final p in plats) {
        if (p.nom.toLowerCase() == nom) {
          plat = p;
          break;
        }
      }
    }
    final base = plat != null ? kcalPlat(plat) : parAssiette(r.repas, r.portions);
    return (base * multiplicateur(r.taille)).round();
  }

  /// Affiche une valeur : « ≈ 650 kcal ».
  static String formater(int kcal) {
    final texte = kcal.abs().toString();
    final morceaux = <String>[];
    for (var fin = texte.length; fin > 0; fin -= 3) {
      morceaux.insert(0, texte.substring(fin - 3 < 0 ? 0 : fin - 3, fin));
    }
    return '≈\u00a0${kcal < 0 ? '-' : ''}${morceaux.join('\u00a0')}\u00a0kcal';
  }
}
