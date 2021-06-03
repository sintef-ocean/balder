import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Controls.Material 2.4
import QtQuick.Layouts 1.11

import fkin.Dds 1.0
import ratatosk 1.0

/// Helper component to transform a GPS coordinate to NED frame
Item {
  id: root;

  /// Latitude decimal degree
  property real lat: 0;
  /// Longitude decimal degree
  property real lon: 0;
  /// Elevation (sealevel is 0)
  property real h: 0;
  /// Earth center earth fixed coordinate for given (lat,lon, h). Homogeneous coordinates (x,y,z,1)
  property vector4d origin_ecef: root.toECEF(lat, lon, h);
  /// Reference to a sinspekto::RatatoskPosInfoSubscriber input signal (DDS)
  property alias posInfo: ddsPosInfo;
  /// Reference to a sinspekto::DdsIdVec3dPublisher output signal (DDS) for North East Down coordinate
  property alias ned: ddsNED;

  RatatoskPosInfoSubscriber { id: ddsPosInfo; }
  DdsIdVec3dPublisher {
    id: ddsNED;
    value: root.toNED(ddsPosInfo.lat, ddsPosInfo.lon, 0);
  }

  /// Initialize DDS data types
  function init(participant, topicPosInfo, topicNED, idNED){

    ddsPosInfo.init(participant, topicPosInfo);
    ddsNED.init(participant, topicNED, idNED, Qt.vector3d(0,0,0), false);

  }

  /// Calculates ECEF coordinates given (lat,lon,h) as NED origin
  function toECEF(latIn, lonIn, height){

    var mu = latIn*Math.PI/180;
    var l = lonIn*Math.PI/180;

    // Fossen 2002 p.42
    var r_e = 6378137; // Equatorial radius of ellipsoid
    var r_p = 6356752; // Polar axis radius of ellipsoid
    var re2 = r_e*r_e;
    var rp2 = r_p*r_p;
    var N = re2/(Math.sqrt(re2*Math.pow(Math.cos(mu),2)
                           + rp2*Math.pow(Math.sin(mu),2)));

    var x = (N + height)*Math.cos(mu)*Math.cos(l);
    var y = (N + height)*Math.cos(mu)*Math.sin(l);
    var z = ((rp2/re2)*N + height)*Math.sin(mu);

    return Qt.vector4d(x,y,z,1);
  }

  /// Calculates NED coordinates for (lat,lon,h) with origin as specified by member properties.
  function toNED(latIn, lonIn, height){

    var ecef = toECEF(latIn, lonIn, height);
    var cosl = Math.cos(lonIn*Math.PI/180);
    var sinl = Math.sin(lonIn*Math.PI/180);
    var cosmu = Math.cos(latIn*Math.PI/180);
    var sinmu = Math.sin(latIn*Math.PI/180);

    var Tne = Qt.matrix4x4(-cosl*sinmu, -sinl, -cosl*cosmu,  0,
                           -sinl*sinmu,  cosl, -sinl*cosmu,  0,
                           cosmu,           0,      -sinmu,  0,
                           0,              0,          0,  1);
    var TneT = Tne.transposed();
    var diff = ecef.minus(origin_ecef);
    diff.w = 1;
    var Gned = TneT.times(diff);
    var ned = Qt.vector3d(Gned.x, Gned.y, Gned.z);
    return ned;
  }
}
