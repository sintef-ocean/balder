import QtQuick 2.11

/// This component holds topic names and ids for DDS member variables in use.
Item {
  id: root;

  /// id string for testing (not in use?),
  property string idTest:               "Test";

  // Purse planner topics
  // same identifier for both commands, notification and data

  /// Id string for purse planner signals
  property string idPursePlanner:       "PursePlanner";
  /// Common topic for program commands sinspekto::DdsCommandPublisher, id changes for different applications
  property string commands:             "fkinCmd";
  /// Common topic for program command responses sinspekto::DdsCommandSubscriber
  property string commandResponses:     "fkinCmdResp";
  /// Common topic for program state notifications sinspekto::DdsStateNotification
  property string stateNotifications:   "fkinStateNotification";

  /// Indicator on whether to keep or reject a received trajectory from purse planner
  property string keepSolution:         "balder_keep_solution";
  // Outputs from purse planner:

  /// Topic for sinspekto::DdsOptiStatusSubscriber, optimization statistics
  property string purseStats:           "mimir_nlp_stats";
  /// Topic for sinspekto::DdsNlpConfigSubscriber, nlp configuration
  property string purseConfig:          "mimir_nlp_config";
  /// Topic for DdsKinematis2DBuffer, suggested vessel trajectory
  property string vesselTrajectory:     "mimir_vessel_trajectory";
  /// Topic for DdsKinematis2DBuffer, expected fish trajectory
  property string fishTrajectory:       "mimir_fish_trajectory";
  /// Topic for RatatoskDoubleValSubscriber, commanded heading rate
  property string vesselRotDesired:     "vessel_course_rate_command";
  /// Topic for RatatoskDouble2Subscriber, expected deploy position
  property string deployPosition:       "vessel_deploy_position";
  /// Topic for RatatoskDouble2Subscriber, expected position for fish colliding with purse
  property string collidePosition:      "fish_collide_position";
  /// Topic for RatatoskDoubleValSubscriber, expected deploy time
  property string deployTime:           "vessel_deploy_time";

  // Vessel pos info signals
  /// Topic for RatatoskPosInfoSubscriber
  property string vesselPosInfo:        "vessel_global_pos_vel";
  /// Topic for DdsIdVec3dPublisher, vesselPosInfo in NED coordinates
  property string localNedTopic:        "balder_local_pos";
  /// Topic for RatatoskDouble2Publisher, TEMPORARY to forcefully set a gps origin instead from pos info topic
  property string gpsOrigin:            "mimir_gps_origin";

  // Pursing Parameters
  /// Topic for DdsIdVec1d, setting speed m/s
  property string vesselSettingSpeed:   "balder_setting_speed";
  /// Topic for DdsIdVec2d, setting radii, [m, m]
  property string vesselSettingRadius:  "balder_setting_radius";
  /// Toppic for DdsIdVec1, aim distance, m
  property string aimPointArcLength:    "balder_aim_point_arc_length";
  property string fishMargin:           "balder_fish_margin";


  // Environment and fish
  /// Topic for RatatoskDouble2Publisher, sea surface current
  property string currentSurface:       "balder_current_surface";
  /// Topic for RatatoskDouble2Publisher, sea current at fish depth
  property string currentFish:          "balder_current_fish";
  /// Id string for fish model
  property string idFish:               "Fish";
  /// Topic for DdsIdVec1dPublisher, depth of fish (manual or from input)
  property string fishDepth:            "balder_fish_depth";
  /// Topic for RatatoskDouble2Publisher, Fish velocity over ground (either manual or from input)
  property string fishVelocityOverGround:    "balder_fish_velocity_over_ground";
  /// Topic for RatatoskPosInfoSubscriber
  property string fishPosInfo:          "fish_global_pos_vel";
  /// Topic for RatatoskDouble3Subscriber, fish position relative to vessel
  property string fishRelativePos:      "fish_relative_pos_3d";

  // Leadline
  /// Id string for leadline model
  property string idLeadline:           "Leadline";
  /// Topic for DdsIdVec2dPublisher, (tau, z_d) parameters for leadline model
  property string leadlineParameters:   "balder_leadline_parameters";
  /// Topic for DdsIdVec1dBuffer, sink response trajectory for a time horizon
  property string leadlineResponse:     "mimir_leadline_response";
  /// Topic for DdsIdVec1d, lead margin below fish at collision, m
  property string leadMargin:           "balder_lead_margin";


}
