require 'test_helper'

class Charta::GeometryTest < ActiveSupport::TestCase
  test 'different E/WKT format input' do
    samples = ['POINT(6 10)',
               'LINESTRING(3 4,10 50,20 25)',
               'POLYGON((1 1,5 1,5 5,1 5,1 1))',
               'MULTIPOINT((3.5 5.6), (4.8 10.5))',
               'MULTILINESTRING((3 4,10 50,20 25),(-5 -8,-10 -8,-15 -4))',
               'MULTIPOLYGON(((1 1,5 1,5 5,1 5,1 1),(2 2,2 3,3 3,3 2,2 2)),((6 3,9 2,9 4,6 3)))',

               'GEOMETRYCOLLECTION(POINT(4 6),LINESTRING(4 6,7 10))',
               'POINT ZM (1 1 5 60)',
               'POINT M (1 1 80)',
               'POINT EMPTY',
               'MULTIPOLYGON EMPTY']

    samples.each_with_index do |sample, index|
      geom1 = Charta.new_geometry(sample, :WGS84)
      geom2 = Charta.new_geometry("SRID=4326;#{sample}")

      assert_equal geom1.to_ewkt, geom2.to_ewkt

      assert_equal geom1.srid, geom2.srid

      assert geom1 == geom2 if index <= 5
      assert geom1.area
    end

    assert Charta.empty_geometry.empty?
  end

  test 'different GeoJSON format input' do
    samples = []
    samples << {
      'type' => 'FeatureCollection',
      'features' => []
    }

    # http://geojson.org/geojson-spec.html#examples
    samples << '{ "type": "FeatureCollection", "features": [   { "type": "Feature",     "geometry": {"type": "Point", "coordinates": [102.0, 0.5]},     "properties": {"prop0": "value0"}     },   { "type": "Feature",     "geometry": {       "type": "LineString",       "coordinates": [         [102.0, 0.0], [103.0, 1.0], [104.0, 0.0], [105.0, 1.0]         ]       },     "properties": {       "prop0": "value0",       "prop1": 0.0       }     },   { "type": "Feature",      "geometry": {        "type": "Polygon",        "coordinates": [          [ [100.0, 0.0], [101.0, 0.0], [101.0, 1.0],            [100.0, 1.0], [100.0, 0.0] ]          ]      },      "properties": {        "prop0": "value0",        "prop1": {"this": "that"}        }      }    ]  }'

    # http://geojson.org/geojson-spec.html#examples
    samples << '{ "type": "FeatureCollection", "features": [ { "type": "Feature", "geometry": {"type": "Point", "coordinates": [102.0, 0.5]}, "properties": {"prop0": "value0"} }, { "type": "Feature", "geometry": { "type": "LineString", "coordinates": [ [102.0, 0.0], [103.0, 1.0], [104.0, 0.0], [105.0, 1.0] ] }, "properties": { "prop0": "value0", "prop1": 0.0 } }, { "type": "Feature", "geometry": { "type": "Polygon", "coordinates": [ [ [100.0, 0.0], [101.0, 0.0], [101.0, 1.0], [100.0, 1.0], [100.0, 0.0] ] ] }, "properties": { "prop0": "value0", "prop1": {"this": "that"} } } ] }'

    # http://geojson.org/geojson-spec.html#examples
    samples << '{ "type": "FeatureCollection",
    "features": [
      { "type": "Feature",
        "geometry": {"type": "Point", "coordinates": [102.0, 0.5]},
        "properties": {"prop0": "value0"}
      },
      { "type": "Feature",
        "geometry": {
          "type": "LineString",
          "coordinates": [
            [102.0, 0.0], [103.0, 1.0], [104.0, 0.0], [105.0, 1.0]
            ]
          },
        "properties": {
          "prop0": "value0",
          "prop1": 0.0
          }
      },
      { "type": "Feature",
         "geometry": {
           "type": "Polygon",
           "coordinates": [
             [ [100.0, 0.0], [101.0, 0.0], [101.0, 1.0],
               [100.0, 1.0], [100.0, 0.0] ]
             ]
         },
         "properties": {
           "prop0": "value0",
           "prop1": {"this": "that"}
           }
      }
       ]
     }'

    samples.each_with_index do |sample, _index|
      geom = Charta.new_geometry(sample)
      assert_equal 4326, geom.srid
    end
  end

  test 'different GML format input' do
    file = File.open(fixture_files_path.join('map.gml'))
    xml = file.read

    assert ::Charta::GML.valid?(xml), 'GML should be valid'
    geom = Charta.new_geometry(xml, nil, 'gml', false)
    assert_equal 4326, geom.srid
  end

  test 'different KML format input' do
    file = File.open(fixture_files_path.join('map.kml'))
    xml = file.read

    assert ::Charta::KML.valid?(xml), 'KML should be valid'
    geom = Charta.new_geometry(xml, nil, 'kml', false)
    assert_equal 4326, geom.srid
  end

  test 'comparison and methods between 2 geometries' do
    samples = ['POINT(6 10)',
               'LINESTRING(3 4,10 50,20 25)',
               'POLYGON((1 1,5 1,5 5,1 5,1 1))',
               'MULTIPOINT((3.5 5.6), (4.8 10.5))',
               'MULTILINESTRING((3 4,10 50,20 25),(-5 -8,-10 -8,-15 -4))',
               'MULTIPOLYGON(((7.40679681301117 48.1167274678089,7.40882456302643 48.1158768860692,7.40882456302643 48.1158679325024,7.40678608417511 48.1167220957579,7.40679681301117 48.1167274678089)))',
               'GEOMETRYCOLLECTION(POLYGON((7.40882456302643 48.1158768860692,7.40679681301117 48.1167274678089,7.40678608417511 48.1167220957579,7.40882456302643 48.1158679325024,7.40882456302643 48.1158768860692)),POINT(4 6),LINESTRING(4 6,7 10))',
               'POINT EMPTY',
               'MULTIPOLYGON EMPTY'].collect do |ewkt|
      Charta.new_geometry("SRID=4326;#{ewkt}")
    end
    last = samples.count - 1
    samples.each_with_index do |geom1, i|
      (i..last).each do |j|
        geom2 = samples[j]
        # puts "##{i} #{geom1.to_ewkt.yellow} ~ ##{j} #{geom2.to_ewkt.blue}"
        unless geom1.collection? && geom2.collection?
          if j == i || (geom1.empty? && geom2.empty?)
            assert_equal geom1, geom2, "#{geom1.to_ewkt} and #{geom2.to_ewkt} should be equal"
          else
            assert geom1 != geom2, "#{geom1.to_ewkt} and #{geom2.to_ewkt} should be different"
          end
        end
        geom1.merge(geom2)
        geom1.intersection(geom2)
        geom1.difference(geom2)
      end
    end
  end

  test 'class cast' do
    samples = {
      'Point' => 'POINT(6 10)',
      'LineString' => 'LINESTRING(3 4,10 50,20 25)',
      'Polygon' => 'POLYGON((1 1,5 1,5 5,1 5,1 1))',
      'MultiPolygon' => 'MULTIPOLYGON(((1 1,5 1,5 5,1 5,1 1),(2 2,2 3,3 3,3 2,2 2)),((6 3,9 2,9 4,6 3)))',
      'GeometryCollection' => 'GEOMETRYCOLLECTION(POINT(4 6),LINESTRING(4 6,7 10))'
    }
    samples.each do |class_name, ewkt|
      assert_equal 'Charta::' + class_name, Charta.new_geometry(ewkt).class.name
    end
  end

  test 'retrieval a GeometryCollection as a valid geojson feature collection' do
    sample = 'GEOMETRYCOLLECTION(POINT(4 6),LINESTRING(4 6,7 10))'
    exp_result = {
      type: 'FeatureCollection',
      features: [
        { type: 'Feature', properties: {}, geometry: { type: 'Point', coordinates: [4, 6] } },
        { type: 'Feature', properties: {}, geometry: { type: 'LineString', coordinates: [[4, 6], [7, 10]] } }
      ]
    }.with_indifferent_access

    geom = Charta.new_geometry(sample)
    json_object = geom.to_json_object(true)

    assert_equal 'Hash', json_object.class.name
    assert json_object.key?('type'), "json should include the 'type' key"
    assert_equal 'FeatureCollection', json_object.try(:[], 'type')

    assert json_object.key?('features'), "json should include the 'features' key"

    json_object.fetch('features', []).each do |feature|
      assert_equal 'Feature', feature.try(:[], 'type')
      assert feature.key?('geometry'), "json should include the 'geometry' key"
      assert_equal 'Hash', feature.class.name
    end

    assert_equal exp_result, json_object
  end
end
