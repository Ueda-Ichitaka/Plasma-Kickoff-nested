/*
    About: checks the plugin metadata of the built Kickoff Nested applet. The
    applet must install next to the system Kickoff (own plugin id), show its
    own name in every locale, and still offer itself as a launcher so it
    appears under "Show Alternatives...".

    SPDX-FileCopyrightText: 2026 Ueda-Ichitaka
    SPDX-License-Identifier: MIT
*/

#include <KPluginMetaData>
#include <QFileInfo>
#include <QJsonObject>
#include <QTest>

class MetadataTest : public QObject
{
    Q_OBJECT

private:
    KPluginMetaData metaData() const
    {
        return KPluginMetaData(QStringLiteral(APPLET_PLUGIN_FILE));
    }

private Q_SLOTS:
    void pluginFileExists()
    {
        QVERIFY2(QFileInfo::exists(QStringLiteral(APPLET_PLUGIN_FILE)), APPLET_PLUGIN_FILE);
    }

    void hasOwnPluginId()
    {
        QCOMPARE(metaData().pluginId(), QStringLiteral("local.kickoffnested"));
    }

    void hasOwnName()
    {
        QCOMPARE(metaData().name(), QStringLiteral("Kickoff Nested"));
    }

    void hasNoTranslatedUpstreamName()
    {
        const QJsonObject kplugin = metaData().rawData().value(QStringLiteral("KPlugin")).toObject();
        for (const QString &key : kplugin.keys()) {
            QVERIFY2(!key.startsWith(QStringLiteral("Name[")), qPrintable(key));
        }
    }

    void isOfferedAsLauncher()
    {
        const QStringList provides = metaData().value(QStringLiteral("X-Plasma-Provides"), QStringList());
        QVERIFY(provides.contains(QStringLiteral("org.kde.plasma.launchermenu")));
    }
};

QTEST_GUILESS_MAIN(MetadataTest)

#include "tst_metadata.moc"
